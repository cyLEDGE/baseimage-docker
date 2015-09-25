#!/usr/bin/env python3




import sys, os, logging, argparse, shutil, re, json
from docker import Client
from tempfile import gettempdir


def setup_logging():
  
  root_handler = logging.StreamHandler(sys.stdout)
  root_formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
  root_handler.setFormatter(root_formatter)
  
  root_logger = logging.getLogger();
  root_logger.addHandler(root_handler)
  root_logger.setLevel(logging.DEBUG)
  


  #ch = logging.StreamHandler(sys.stdout)
  #ch.setLevel(logging.DEBUG)
  #formatter = logging.Formatter('%(asctime)s DOCKER: %(message)s')
  #ch.setFormatter(formatter)
  
  #docker_logger = logging.getLogger('docker')
  #docker_logger.addHandler(ch)
  #docker_logger.setLevel(logging.DEBUG)






def create_build_copy( src_build_dir, tmp_build_dir=None ):
  if not tmp_build_dir:
    tmp_build_dir = tempfile.mkdtemp(prefix='docker_build_x_')
  logging.debug("copy build dir from %s to %s" % (src_build_dir, tmp_build_dir))
  shutil.copytree(src_build_dir, tmp_build_dir)
  return tmp_build_dir


def remove_build_copy( tmp_build_dir ):
  logging.debug("remove build dir at %s" % tmp_build_dir)
  shutil.rmtree(tmp_build_dir)




def dockerfile_get_FROM( dockerfile ):
  with open(dockerfile, 'r') as fin:
    dockerfile_contents = fin.read()
    tag_matches = re.search(r'FROM (?P<image>[^\s:]+)(?::(?P<tag>[^\s]+))?', dockerfile_contents)
    if not tag_matches:
      return None
    return tag_matches.groupdict({'image':None, 'tag':None})


def dockerfile_set_FROM( dockerfile, image, tag=None ):
  import fileinput
  fromRegEx = re.compile(r'FROM [^\s:]+(?::[^\s]+)?')
  
  if tag:
    FROM = "%s:%s" % (image,tag)
  else:
    FROM = "%s" % (image)
  
  
  with open(dockerfile, 'r') as f:
    contents = f.read()
    contents = fromRegEx.sub('FROM %s' % FROM, contents, 1)
    f.close()
      
  with open(dockerfile, 'w') as f:
    f.write(contents)
    f.close()
  
  logging.info("Set Dockerfile FROM %s" % FROM)




def docker_build( build_dir, tag="cyledge/base", dockerfile="Dockerfile"):

  logger = logging.getLogger("docker")
  logging.info("Building docker image %s" % tag)
  
  #dockerfile = "%s/%s" % (build_dir, dockerfile)
  
  c = Client(base_url='unix://var/run/docker.sock')
  build_output = c.build(
    path=build_dir,
    dockerfile=dockerfile,
    tag=tag,
    stream=True
    )

  last_line = None
  for line in build_output:
    output = json.loads(line.decode('UTF-8'))
    if "stream" in output:
      logger.debug(output["stream"].rstrip())
      last_line = output["stream"]
    if "error" in output:
      logger.error(output["error"].rstrip())
      #logger.error(output["errorDetail"])
    
  srch = r'Successfully built ([0-9a-f]+)'
  match = re.search(srch, last_line)
  if not match:
    raise RuntimeError()
  else:
    return match.group(1)
    
  






if __name__ == '__main__':
  
  setup_logging()
  
  if (sys.version_info < (3, 0)):
    logging.error("This script requires python version 3")
    sys.exit(1)
    
  
  current_directory = os.path.dirname( os.path.abspath(__file__) )
  default_build_dir = "%s/image" % current_directory
  
  parser = argparse.ArgumentParser(description='Docker image builder.')
  parser.add_argument('--dir', '-d', default=default_build_dir, help="Build directory to use (default: ./image)")
  parser.add_argument('--release', '-r', default="14.04", help="Ubuntu release to build from (default: 14.04)")
  
  args = parser.parse_args()
  
  
  tmp_build_dir="%s/docker_build_dir" % gettempdir()
  tmp_dockerfile = "%s/Dockerfile" % tmp_build_dir
  
  image_tag = "cyledge/base:%s" % args.release
  
  if os.path.exists(tmp_build_dir):
    logging.error("Temporary build dir already exists. Maybe another build process is currently running..");
    logging.error("Restart once the directory %s does not exist anymore" % tmp_build_dir);
    sys.exit(1)
  
  if not os.path.exists( args.dir ):
    logging.error("Build directory not found: %s" % args.dir)
    sys.exit(1)
  
  if not os.path.exists( "%s/Dockerfile" % args.dir ):
    logging.error("Build directory does not contain a Dockerfile")
    sys.exit(1)
  
  try:
    create_build_copy(args.dir, tmp_build_dir)
    dockerfile_set_FROM(tmp_dockerfile, "ubuntu", args.release)
    real_from = dockerfile_get_FROM(tmp_dockerfile)
    
    docker_build(tmp_build_dir, tag=image_tag)
    
    logging.info("build complete")
  except Exception as e:
    logging.error("faild to build image")
    raise
  finally:
    remove_build_copy(tmp_build_dir)
  
  
  
  
  
  
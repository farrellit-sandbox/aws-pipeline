
lightweight cloudformation AWS all-inclusive infrastructure CI pipeline

# Introduction

2 things are provided here 
  
  1. cloudformation template library
  2. self-updating codepipeline template and bootstrapping process

## Components of the codebase 

<dl>
  <dt>`templates/`</dt>
<dd>
  reusable cloudformation templates
</dd>
<dt>
`deployments/`
</dt>
<dd>
  configuration for those stacks, and a top level stack that pulls in the templates. 
<dt>
`publish_templates.py` `test_publish_templates.py` `Dockerfile.pytest` `make`
</dt>
<dd>
  when the cloudformation stack is generated, the stack templates have to be published to s3.  this python script, run from buildspec.yml, handles that 
  task.  each file is sha256 hashed after being "json normalized", then uploaded to s3 and the reference in the other templates is updated from file:// to 
  http://s3.amazonaws....  The final stack entrypoint is then shipped back in the form of a build artifact component.  

  The rest of those files support those tests.  
  
<dd>
</dl>

# Infrastructure CI Pipeline


## general notes:
- the pipeline itself must also be CI'd for this to work.  That's why the main pipeline deploys itself before it deploys the stack entrypoint.  
- Other pipelines are included here and updated if this changed but point to different repos for auto deploy

## Processes

### First time setup

nothing can bootstrap itself of course; not quite.  So `bootstrap.sh` exists to kick off the process for the first time.  Once run, the script will:

1. ensure a region is set in the environment variable AWS_DEFAULT_REGION, or collect one
2. ensure AWS Authentication and CLI commands are working
3. collect the entrypoint configs from the user  (defaulting to the farrellit-sandbox demonstration included in the repo )
4. dreive the "main" stack name from an input that the pipeline expects
5. invoke a create or update stack template on a pipeline stack pointing at the pipeline config indicated by the user, which 
    in turn then creates the main stack (see below)

TODO: this should maybe actually invoke `publish_templates.py` in dryrun to validate all the templates you select!

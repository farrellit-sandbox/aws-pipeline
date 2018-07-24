#!/usr/bin/env bash
# check if oauth token exists or get instructions out for generating an oauth token
while [ -z ${AWS_DEFAULT_REGION+x} ]; do
  echo -n "Aws region? "
  read AWS_DEFAULT_REGION
done
export AWS_DEFAULT_REGION

if ! aws sts get-caller-identity; then 
  echo "Looks like aws authentication isn't working right now."
  exit 1
fi

# set up ssm parameter for token

if aws ssm get-parameter --name /deployment/github/oauth > /dev/null ; then
  echo "Github token loaded into SSM already."

else
  echo -n "Githu oauth token? "
  read token
  echo $AWS_DEFAULT_REGION
  aws ssm put-parameter --name /deployment/github/oauth --type String --value "$token"
fi

default_pipeline_config="deployments/farrellit-sandbox/dev-pipeline.json"
echo -n "Pipeline Configuraiton? [ $default_pipeline_config ] ?"
read pipeline_config
pipeline_config="${pipeline_config:-$default_pipeline_config}"

default_entrypoint="deployments/farrellit-sandbox/site.json"
echo -n "Entrypoint ? [ $default_entrypoint ] ?"
read entrypoint
entrypoint="${entrypoint:-$default_entrypoint}"


set -e
stack_name="`python -c 'import json,sys; f=open(sys.argv[1]); data=json.loads(f.read()); sys.stdout.write(data["Parameters"]["ProjectName"])' "${pipeline_config}" `"
echo "Stack name will be $stack_name"
echo "Validating pipeline stack template"
aws cloudformation validate-template --template-body file://templates/pipeline.json
echo "Validating entrypoint stack template $entrypoint"
aws cloudformation validate-template --template-body file://${entrypoint}
if aws cloudformation describe-stacks --stack-name "$stack_name" ; then action="update-stack"; else action="create-stack --on-failure DELETE"; fi
aws cloudformation $action --stack-name "$stack_name" --capabilities CAPABILITY_IAM --template-body file://templates/pipeline.json \
  --parameters "`python -c 'import json,sys; f=open(sys.argv[1]); data=json.loads(f.read()); sys.stdout.write(json.dumps([{"ParameterKey":k,"ParameterValue": data["Parameters"][k]} for k in data["Parameters"].keys() ],indent=None,separators=(",",":") ))' "${pipeline_config}" `"

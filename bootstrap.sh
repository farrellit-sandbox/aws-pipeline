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


stack_name="`python -c 'import json,sys; f=open(sys.argv[1]); data=json.loads(f.read()); sys.stdout.write(data["ProjectName"])' "${pipeline_config}" `"
echo "Stack name will be $stack_name"
set -e
echo "Validating pipeline stack template"
aws cloudformation validate-template --template-body file://templates/pipeline.json
echo "Validating entrypoint stack template $entrypoint"
aws cloudformation validate-template --template-body file://${entrypoint}
aws cloudformation create-stack --stack-name "$stack_name" --capabilities CAPABILITY_IAM --on-failure DELETE --template-body file://templates/pipeline.json \
  --parameters "`python -c 'import json,sys; f=open(sys.argv[1]); data=json.loads(f.read()); sys.stdout.write(json.dumps([{"ParameterKey":k,"ParameterValue": data[k]} for k in data.keys() ],indent=None,separators=(",",":") ))' "${pipeline_config}" `"

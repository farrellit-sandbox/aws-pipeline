# run this with the proper keys!
iam_stack_name = "IamMgmt"

interim-users: 
	aws --region $${AWS_REGION:-us-east-2} cloudformation validate-template --template-body file://iam.json
	if ! aws --region $${AWS_REGION:-us-east-2} cloudformation describe-stacks --stack-name $(iam_stack_name)> /dev/null 2>&1; then \
    aws --region $${AWS_REGION:-us-east-2} cloudformation create-stack --template-body file://iam.json --stack-name $(iam_stack_name) --capabilities CAPABILITY_NAMED_IAM; \
    else \
    aws --region $${AWS_REGION:-us-east-2} cloudformation update-stack --template-body file://iam.json --stack-name $(iam_stack_name) --capabilities CAPABILITY_NAMED_IAM; \
    fi
      
 
# this uses its own stack to autodeploy itself
bootstrap: 


# run this with the proper keys!
interim-users: 
	aws --region $${AWS_REGION:-us-east-2} cloudformation validate-template --template-body file://users.json
	aws --region $${AWS_REGION:-us-east-2} cloudformation create-stack --template-body file://users.json --stack-name IamUserMgmt --capabilities CAPABILITY_NAMED_IAM
 
# this uses its own stack to autodeploy itself
bootstrap: 


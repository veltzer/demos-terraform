#!/bin/bash -e

values=$(terraform output -json)

((i=0))
for username in $(echo "${values}" | jq -r '.students.value[].name')
do
	{
		echo "Instructions repo:     https://github.com/davewadestein/terraform-workshop"
		echo "Console URL:           https://introterraform.signin.aws.amazon.com/console"
		echo "Username/Alias:        ${username}"
		password=$(echo "${values}" | jq -r '.passwords.value[]['"${i}"']' | base64 --decode | gpg -dq)
		echo "AWS Console Password:  ${password}"
		region=$(echo "${values}" | jq -r '.students.value['"${i}"'].region')
		echo "Exercise 11 Region:    ${region}"
		echo "Link to the slides:    http://bit.ly/terraform-day-1"
		echo "Instructor email:      dave@developintelligence.com"
		#echo "Course Evaluation:     $(cat survey-link)"
		echo ""
		echo ""
		echo ""
	} > "tf-user${i}"
	((i=i+1))
done

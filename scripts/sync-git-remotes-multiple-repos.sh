#!/bin/bash -e
# debug options include -v -x
# sync-git-remotes-multiple-repos
# A script to reconfigure the git remotes to push to multiple git repositories, i.e.
# to GitHub and AWS CodeCommit.

#-----------------------------
# Request Named Profile
AWS_PROFILE="default"
while true
do
  # -e : stdin from terminal
  # -r : backslash not an escape character
  # -p : prompt on stderr
  # -i : use default buffer val
  read -er -i "$AWS_PROFILE" -p "Enter Project AWS CLI Named Profile ...........: " USER_INPUT
  if aws configure list-profiles 2>/dev/null | grep -qw -- "$USER_INPUT"
  then
    echo "Project AWS CLI Named Profile is valid ........: $USER_INPUT"
    AWS_PROFILE=$USER_INPUT
    break
  else
    echo "Error! Project AWS CLI Named Profile invalid ..: $USER_INPUT"
  fi
done
#.............................

#-----------------------------
# Request Region
AWS_REGION=$(aws configure get region --profile "$AWS_PROFILE")
while true
do
  # -e : stdin from terminal
  # -r : backslash not an escape character
  # -p : prompt on stderr
  # -i : use default buffer val
  read -er -i "$AWS_REGION" -p "Enter Project AWS CLI Region ..................: " USER_INPUT
  if aws ec2 describe-regions --profile "$AWS_PROFILE" --query 'Regions[].RegionName' \
    --output text 2>/dev/null | grep -qw -- "$USER_INPUT"
  then
    echo "Project AWS CLI Region is valid ...............: $USER_INPUT"
    AWS_REGION=$USER_INPUT
    break
  else
    echo "Error! Project AWS CLI Region is invalid ......: $USER_INPUT"
  fi
done
#.............................

#-----------------------------
# Request Project Name
PROJECT_NAME="cfn-iam-groups-users-roles"
while true
do
  # -e : stdin from terminal
  # -r : backslash not an escape character
  # -p : prompt on stderr
  # -i : use default buffer val
  read -er -i "$PROJECT_NAME" -p "Enter the Name of this Project ................: " USER_INPUT
  if [[ "${USER_INPUT:=$PROJECT_NAME}" =~ (^[a-z0-9]([a-z0-9-]*(\.[a-z0-9])?)*$) ]]
  then
    echo "Project Name is valid .........................: $USER_INPUT"
    PROJECT_NAME=$USER_INPUT
    # Doc Store for this project
    PROJECT_BUCKET="proj-${PROJECT_NAME}"
    break
  else
    echo "Error! Project Name must be S3 Compatible .....: $USER_INPUT"
  fi
done
#.............................

#-----------------------------
# Request ECR description
REPO_DESCRIPTION=\
"Cloudformation templates that create a hierarchical set of groups, users and \
roles for use in a stand-alone AWS development account. A distinction is made \
between Console Users and Programmatic Users. A default password is supplied \
to Console Users and Secret Access Keys are generated for Programmatic Users. \
The Console Administrator Account is created within the Root Account and the \
hierarchical collection of groups and users is then created within that Console \
Administrator Account."
while true
do
  # -e : stdin from terminal
  # -r : backslash not an escape character
  # -p : prompt on stderr
  # -i : use default buffer val
  read -er -i "$REPO_DESCRIPTION" -p "Enter the description here ....................: " USER_INPUT
  if [[ "${USER_INPUT:=$REPO_DESCRIPTION}" =~ (^[a-zA-Z0-9(). -:\']*$) ]]
  then
    echo "Check Valid Comment ...........................: PASS"
    REPO_DESCRIPTION=$USER_INPUT
    break
  else
    echo "Check Valid Comment ...........................: FAIL"
  fi
done
#.............................


#-----------------------------
# Create a mirror repository in AWS CodeCommit and configure to push origin.
cd ..
REPO_GIT=$(git config --get remote.origin.url)


REPO_NAME=$(echo "$REPO_GIT" | grep -o -P '(?<=git@github.com:cloudemprise/).*(?=.git)')

git remote rm origin

git remote add origin "$REPO_GIT"

git remote set-url --add --push origin "$REPO_GIT"

REPO_AWS=$(aws codecommit create-repository --repository-name "$REPO_NAME" --output text \
  --repository-description "$REPO_DESCRIPTION" --query "repositoryMetadata.cloneUrlSsh"  \
  --tags Function="cert-devops",Project="demo",Reference="script")

git remote set-url --add --push origin "$REPO_AWS"

git push --set-upstream origin main
#.............................


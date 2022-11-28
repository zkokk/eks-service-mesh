# COSG-WEBAPP
Cosg-webapp is simple web application created by "Container and Orchestration" specialty group for testing purposes.
Application will be used in onboarding task which need to be performed from new members of the group.

Application prints simple message on coloured background. 
Color of the background could be provided with "--color" flag and the name it name based on the following list of allowed colors "red", "green", "blue", "blue2", "darkblue" and "pink". If the application is started without any flags it will choose one of the allowed colors on a random base.

## How to run the application:
1. Clone the repository with the application code <repo to the code>
2. Compose Dockerfile based on “Container and Orchestration“ simple webapp requirements:
   2.1. Our simple webapp is written on Python3.6.
   2.2. Application require “Flask“.
   2.3. Copy cloned application source code from our repo to “/opt/" directory inside the image and configure this directory as working directory.
   2.4. Application need to be exposed on port 8080.
   2.5. Application is started with “python app.py“ command.
   2.6. Build docker image from the Dockerfile which you created in the previous step.
3. Directly start it via docker on you workstation or push the new image to your ECR repository and then deploy to EKS cluster.

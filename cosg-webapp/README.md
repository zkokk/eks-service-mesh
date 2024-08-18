# COSG-WEBAPP
Cosg-webapp is simple web application created by "Container and Orchestration" specialty group for testing purposes.
Application will be used in onboarding task which need to be performed from new members of the group.

Application prints simple message on colored background. 
Color of the background could be provided with "--color" flag and its name based on the following list of allowed colors "red", "green", "blue", "blue2", "darkblue" and "pink". If the application is started without any flags it will choose one of the allowed colors on a random base.

## How to run the application:
1. Clone this repository
2. Compose Dockerfile based on “Container and Orchestration“ simple webapp requirements:
>* Our simple webapp is written on Python3.6.
>* Application require “Flask“.
>* Copy/Add [cosg-webapp](cosg-webapp) application source to “/opt/" directory inside the image 
>* Configure /opt as working directory.
>* Application need to be exposed on port 8080.
>* Application is started with “python app.py“ command.
>* Build docker image from the Dockerfile which you created in the previous step.
3. You can directly start it via docker on you workstation and check if it is running on [localhost:8080](localhost:8080)
4. Push the new image to your ECR repository and then deploy to EKS cluster.

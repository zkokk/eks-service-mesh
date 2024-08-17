FROM python:3.6
COPY . /opt
RUN pip install Flask
EXPOSE 8080
WORKDIR /opt
CMD ["python", "app.py"]
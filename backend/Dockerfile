FROM python:3.14-rc-slim

WORKDIR /application

COPY r*.txt .

RUN pip install -r requirements.txt 

COPY main.py .

EXPOSE 3000

CMD [ "python","app.py" ]
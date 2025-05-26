FROM python:3

WORKDIR /app

COPY src/* /app

RUN pip install -r requirements.txt

EXPOSE 5000

CMD ["python" ,"main.py"]
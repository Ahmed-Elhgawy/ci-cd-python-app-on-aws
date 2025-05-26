FROM python:3

WORKDIR /app

COPY src/* /app

RUN pip install -r requirement.txt

EXPOSE 5000

CMD ["python" ,"main.py"]
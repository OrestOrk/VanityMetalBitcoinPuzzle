FROM swift:5.10-jammy
RUN apt-get update && apt-get install -y python3 python3-pytest && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY . .
CMD ["sh", "-c", "python3 Tools/verify_model.py && python3 Tools/verify_targets.py"]

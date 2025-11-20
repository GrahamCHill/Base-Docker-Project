FROM golang:1.25
LABEL authors="grahamhill"

WORKDIR /app
COPY . .

RUN go mod init backend-go || true
RUN go build -o server main.go

CMD ["./server"]

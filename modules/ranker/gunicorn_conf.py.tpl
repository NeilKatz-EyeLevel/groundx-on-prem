infolog = "-"
accesslog = "-"
errorlog = "-"

loglevel = "info"
workers = ${workers}
threads = ${threads}
timeout = 120

worker_class = "uvicorn.workers.UvicornWorker"

bind = "0.0.0.0:8080"

wsgi_app = "search_server:app"
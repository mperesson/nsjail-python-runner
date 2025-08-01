lock:
	uv lock
	uv export > requirements.txt
	uv export --group sandbox > requirements-sandbox.txt

build:
	docker build -t python-nsjail .

run:
	docker run --rm -p 5000:5000 --privileged python-nsjail

lint:
	ruff check --fix
	ruff format
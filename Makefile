build:
	docker build -t ainoya/circleci-infra-tools .
push::
	docker push ainoya/circleci-infra-tools
run:
	docker run -it --rm ainoya/circleci-infra-tools bash

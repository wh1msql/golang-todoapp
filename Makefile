include .env
export

export PROJECT_ROOT=$(shell pwd)

env-up:
	@docker compose up -d todoapp-postgres

env-down:
	@docker compose down todoapp-postgres

env-cleanup:
	@read -r -p "Danger! Risk of data loss. Clear all environment volume files? [y/N]: " confirm; \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		docker compose down todoapp-postgres port-forwarder && \
		sudo rm -rf /var/lib/todoapp-postgres && \
		echo "Environment files have been cleared."; \
	else \
		echo "Environment cleanup cancelled."; \
	fi

env-port-forward:
	@docker compose up -d port-forwarder

env-port-close:
	@docker compose down port-forwarder

migrate-create:
	@if [ -z "$(seq)" ]; then \
		echo "Missing value for the \`seq\` parameter."; \
		echo "e.g. make migrate-create seq=val"; \
		exit 1; \
	fi; \
	docker compose run --rm todoapp-postgres-migrate \
		create \
		-ext sql \
		-dir /migrations \
		-seq "$(seq)"

migrate-remove:
	@read -r -p "Danger! This will delete all migration files. Continue? [y/N]: " confirm; \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		sudo rm -f migrations/*.sql; \
		echo "Migration files removed."; \
	else \
		echo "Cancelled."; \
	fi

migrate-action:
	@if [ -z "$(action)" ]; then \
		echo "Missing value for the \`action\` parameter."; \
		echo "e.g. make migrate-action action=val"; \
		exit 1; \
	fi; \
	docker compose run --rm todoapp-postgres-migrate \
		-path /migrations \
		-database postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@todoapp-postgres:5432/${POSTGRES_DB}?sslmode=disable \
		"$(action)"

migrate-up:
	@make migrate-action action=up

migrate-down:
	@make migrate-action action=down

todoapp-run:
	@export LOGGER_FOLDER=$(PROJECT_ROOT)/out/logs && \
	export POSTGRES_HOST=localhost && \
	go mod tidy && \
	go run cmd/todoapp/main.go
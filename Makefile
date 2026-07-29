##
## {{DDEV_NAME}} - dev environment
## Usage: make <target>
##

.PHONY: help start stop restart open logs si install enable cr \
        test lint lint-fix stan check format format-check twig-lint twig-fix \
        spell lint-js lint-css module-ci \
        mod-log mod-status mod-fetch mod-branch tag switch mr \
        guard-module-name guard-module-git

MODULE = {{MODULE_PATH}}
MODULE_NAME = {{MODULE_NAME}}

## == Environment ==============================================================

help: ## Show this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage: make \033[36m<target>\033[0m\n\nTargets:\n"} \
	/^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

start: ## Start DDEV
	ddev start

stop: ## Stop DDEV
	ddev stop

restart: ## Restart DDEV
	ddev restart

open: ## Open site in browser
	ddev launch

logs: ## Tail web server logs
	ddev logs -f

## == Drupal ===================================================================

si: ## Fresh Drupal install (LocalGov profile)
	ddev drush si localgov -y
	ddev drush cr

install: ## Clean install, choose a profile (Standard/LocalGov/Microsites/...)
	./scripts/install-drupal

guard-module-name:
	@if [ -z "$(MODULE_NAME)" ]; then \
	  echo "No module configured (site-only project). Add one under web/modules/custom/ and set MODULE_NAME in the Makefile."; \
	  exit 1; \
	fi

enable: guard-module-name ## Enable the module
	ddev drush en $(MODULE_NAME) -y
	ddev drush cr

cr: ## Clear Drupal caches
	ddev drush cr

## == Quality ==================================================================

test: ## Run the module PHPUnit tests
	ddev exec vendor/bin/phpunit -c web/core $(MODULE)

lint: ## Run PHPCS against the module
	ddev exec vendor/bin/phpcs $(MODULE)

lint-fix: ## Auto-fix PHPCS violations with PHPCBF
	ddev exec vendor/bin/phpcbf $(MODULE)

stan: ## Run PHPStan static analysis
	ddev exec vendor/bin/phpstan analyse $(MODULE)

twig-lint: ## Lint Twig templates
	ddev exec vendor/bin/twig-cs-fixer lint $(MODULE)

twig-fix: ## Auto-fix Twig template violations
	ddev exec vendor/bin/twig-cs-fixer lint $(MODULE) --fix

check: lint stan test twig-lint ## Run all quality checks (lint + stan + test + twig-lint)

format: ## Format front-end assets with Prettier (CSS/JS/JSON/YAML/MD)
	ddev exec npx prettier --write "$(MODULE)/**/*.{css,js,json,yml,yaml,md}"

format-check: ## Check Prettier formatting without writing
	ddev exec npx prettier --check "$(MODULE)/**/*.{css,js,json,yml,yaml,md}"

## == drupal.org pipeline parity ===============================================

module-ci: guard-module-name ## Copy the drupal.org GitLab CI pipeline into the module
	@if [ -f "$(MODULE)/.gitlab-ci.yml" ]; then \
	  echo "$(MODULE)/.gitlab-ci.yml already exists, not overwriting."; \
	  exit 1; \
	fi
	cp assets/module.gitlab-ci.yml "$(MODULE)/.gitlab-ci.yml"
	@echo "Copied assets/module.gitlab-ci.yml to $(MODULE)/.gitlab-ci.yml"

## == Maintainer (module git) ==================================================

guard-module-git:
	@if [ -z "$(MODULE_NAME)" ] || [ ! -d "$(MODULE)/.git" ]; then \
	  echo "No module git checkout to operate on (site-only project)."; \
	  exit 1; \
	fi

mod-log: guard-module-git ## Recent module commits (usage: make mod-log or make mod-log N=40)
	git -C $(MODULE) log --oneline -$${N:-20}

mod-status: guard-module-git ## Git status of the module
	git -C $(MODULE) status

mod-fetch: guard-module-git ## Fetch latest from upstream
	git -C $(MODULE) fetch origin
	@echo ""
	@git -C $(MODULE) log --oneline -5 origin/$$(git -C $(MODULE) rev-parse --abbrev-ref HEAD)

mod-branch: guard-module-git ## List branches and show current
	git -C $(MODULE) branch -av

tag: guard-module-git ## Tag and push a release  (usage: make tag VERSION=1.0.0-alpha1)
	@test -n "$(VERSION)" || (echo "Usage: make tag VERSION=1.0.0-alpha1" && exit 1)
	git -C $(MODULE) tag $(VERSION)
	git -C $(MODULE) push origin $(VERSION)
	@echo "Tagged and pushed $(VERSION)"

switch: guard-module-git ## Switch module branch  (usage: make switch BRANCH=1.0.x)
	@test -n "$(BRANCH)" || (echo "Usage: make switch BRANCH=1.0.x" && exit 1)
	git -C $(MODULE) checkout $(BRANCH)

mr: guard-module-git ## Check out a contributor MR for review  (usage: make mr MR=123)
	@test -n "$(MR)" || (echo "Usage: make mr MR=123" && exit 1)
	git -C $(MODULE) fetch origin merge-requests/$(MR)/head:mr-$(MR)
	git -C $(MODULE) checkout mr-$(MR)

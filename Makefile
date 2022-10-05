SHELL:=/bin/bash
ROOT_PATH:=$(abspath $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST))))))

.DEFAULT_GOAL:=help

#############################################################################
.PHONY: help
help: ## This help
	@grep --no-filename -E '^[a-zA-Z_/-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'
#############################################################################


#############################################################################
.PHONY: dist
dist: ## Create dist
	@mkdir -p $(ROOT_PATH)/dist $(ROOT_PATH)/tmp
	@cp $(ROOT_PATH)/install.sh $(ROOT_PATH)/dist/index.html
	@cp $(ROOT_PATH)/add-server.sh $(ROOT_PATH)/dist/add-server.html
	@cp $(ROOT_PATH)/version.json $(ROOT_PATH)/dist/version.json
	@curl "https://download.maxmind.com/app/geoip_download?edition_id=GeoLite2-Country&license_key=$(GEOLITE_LICENSE)&suffix=tar.gz" | tar -zx -C $(ROOT_PATH)/tmp
	@cp $(ROOT_PATH)/tmp/$$(ls $(ROOT_PATH)/tmp/ | head -n 1)/*.mmdb $(ROOT_PATH)/dist/GeoLite2-Country.mmdb
	@echo -e "User-agent: *" >>$(ROOT_PATH)/dist/robots.txt
	@echo -e "Disallow: /" >>$(ROOT_PATH)/dist/robots.txt
	@rm -rf $(ROOT_PATH)/tmp
#############################################################################


#############################################################################
%: ## A parameter
	@true
#############################################################################

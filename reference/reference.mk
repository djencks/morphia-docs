MAKE_ROOT = $(shell while [ ! -d .git ]; do cd ..; done; pwd )

include $(MAKE_ROOT)/variables.mk

$(MORPHIA_REPO):
	[ -d $@ ] || git clone $(MORPHIA_GITHUB) $@

branch: $(MORPHIA_REPO)
	cd $(MORPHIA_REPO) ; git checkout $(BRANCH)

version.toml: $(POM) Makefile ../reference.mk ../version.template.toml
	cat ../version.template.toml | \
		sed -e "s/ARTIFACT/$(ARTIFACT)/g" | \
		sed -e "s/MAJOR/$(MAJOR)/g" | \
		sed -e "s/STATUS/$(RELEASE_STATUS)/g" | \
		sed -e "s/VERSION/$(CURRENT)/g" | \
		tee version.toml

data/morphia.toml: $(POM) Makefile ../reference.mk
	@echo Updating documentation to use $(CURRENT) for the current version
	@echo with the major version of $(MAJOR) and driver version of $(DRIVER).
	@sed -e "s/currentVersion.*/currentVersion = \"$(CURRENT)\"/" \
	 	-e "s/majorVersion.*/majorVersion = \"$(MAJOR)\"/" \
		-e "s|coreApiUrl.*|coreApiUrl = \"http://mongodb.github.io/mongo-java-driver/$(DRIVER)/javadoc/\"|" \
		-e "s|gitBranch.*|gitBranch = \"$(BRANCH)\"|" \
		data/morphia.toml > data/morphia.toml.sed
	@mv data/morphia.toml.sed data/morphia.toml

	@sed -e "s|<span id=\"version-tag\">.*|<span id=\"version-tag\">$(TEXT)</span>|" \
		layouts/partials/logo.html > layouts/partials/logo.html.sed
	@mv layouts/partials/logo.html.sed layouts/partials/logo.html

$(JAVADOC)/index.html: $(shell find $(CORE)/src/main/java -name *.java)
	mvn -f $(CORE) clean javadoc:javadoc

public/index.html: $(POM) $(shell find . | grep -v public) $(shell find ../commmon)
	@$(HUGO)

all: public/index.html $(JAVADOC)/index.html
	@mkdir -p public/javadoc
	@rsync -ra $(JAVADOC)/ public/javadoc

publish: all
	rsync -ra --delete public/ $(GH_PAGES)/$(MAJOR)
	cd $(GH_PAGES) ; git add $(MAJOR)

watch: all
	$(HUGO) server --baseUrl=http://localhost/ --buildDrafts --watch

clean:
	rm -rf public

.PHONY: all
.DEFAULT_GOAL := all

MORPHIA_REPO=/tmp/morphia-for-docs
POM = $(MORPHIA_REPO)/pom.xml
MAVEN_HELP = org.apache.maven.plugins:maven-help-plugin:2.1.1:evaluate
CURRENT = $(shell mvn -f $(POM) $(MAVEN_HELP) -Dexpression=project.version | grep -v INFO)
DRIVER = $(shell mvn -f $(POM) $(MAVEN_HELP) -Dexpression=driver.version | grep -v INFO)
HUGO = hugo --themesDir=../../themes

MAJOR = $(shell echo ${CURRENT} | sed -e 's/-SNAPSHOT//' -e 's/.[0-9]*$$//')
SRC_LINK = "https://github.com/MorphiaOrg/morphia/tree/$(BRANCH)"
TEXT = Morphia $(MAJOR)
CORE = $(MORPHIA_REPO)/morphia
JAVADOC = $(CORE)/target/site/apidocs

$(MORPHIA_REPO):
	[ -d $@ ] || git clone git@github.com:MorphiaOrg/morphia.git $@

branch: $(MORPHIA_REPO)
	cd $(MORPHIA_REPO) ; git checkout $(BRANCH)

data/morphia.toml: $(POM) Makefile ../main.mk
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

public/index.html: $(POM) $(shell find . | grep -v public)
	@$(HUGO)

all: public/index.html $(JAVADOC)/index.html
	@mkdir -p public/javadoc
	@rsync -ra $(JAVADOC)/ public/javadoc

publish: all
	rsync -ra --delete public/ ../../target/gh-pages/$(MAJOR)
	cd ../../target/gh-pages/ ; git add $(MAJOR)

watch: all
	$(HUGO) server --baseUrl=http://localhost/ --buildDrafts --watch

clean:
	rm -rf public

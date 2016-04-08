# # Put in your GitHub account details.
# 
# # Gerbv PCB image preview parameters - colours, plus resolution.
-include gerbv_colors.mk # load colors 

GERBER_IMAGE_RESOLUTION?=600
BACKGROUND_COLOR?=\#006600
HOLES_COLOR?=\#000000
SILKSCREEN_COLOR?=\#ffffff
PADS_COLOR?=\#FFDE4E
TOP_SOLDERMASK_COLOR?=\#009900
BOTTOM_SOLDERMASK_COLOR?=\#2D114A
GERBV_OPTIONS= --export=png --dpi=$(GERBER_IMAGE_RESOLUTION) --background=$(BACKGROUND_COLOR) --border=1

# Github vars
github_org = $(shell git config github.org)
github_user = $(shell git config github.user)
github_token = $(shell git config github.token)
mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
current_dir := $(notdir $(patsubst %/,%,$(dir $(mkfile_path))))


# # STUFF YOU WILL NEED:
# #  gerbv and eagle must be installed and must be in path.
# 
# # On Mac OSX we will create a link to the Eagle binary:
# # sudo ln -s /Applications/EAGLE/EAGLE.app/Contents/MacOS/EAGLE /usr/bin/eagle 

schematics := $(wildcard *.sch)
boards := $(wildcard *.brd)
drawings := $(wildcard *.dxf)
gerbers := $(patsubst %.brd,%_gerber.zip,$(boards))
pngs := $(patsubst %.brd,%.png,$(boards)) $(patsubst %.dxf,%.png,$(drawings))
dris := $(patsubst %.brd,%.dri,$(boards))
gpis := $(patsubst %.brd,%.gpi,$(boards))
back_pngs := $(patsubst %.brd,%_back.png,$(boards))
mds := $(patsubst %.brd,%.md,$(boards))

# .SILENT: all git github clean

.SECONDARY: $(pngs) $(mds)

.INTERMEDIATE: $(dris) $(gpis)

.IGNORE: push

.PHONY: pngs clean clean_gerbers clean_temps clean_pngs clean_zips clean_mds all

all: push

pngs: $(pngs) $(back_pngs)

README.md: Intro.md $(mds)
	cat $+ > README.md 
	rm -f $(mds)

%.GTL: %.brd
	eagle -X -d GERBER_RS274X -o $@ $< Top Pads Vias Dimension

%.GBL: %.brd
	eagle -X -d GERBER_RS274X -o $@ $< Bottom Pads Vias Dimension

%.GTO: %.brd
	eagle -X -d GERBER_RS274X -o $@ $< tPlace tNames tValues

%.GTP: %.brd
	eagle -X -d GERBER_RS274X -o $@ $< tCream

%.GBO: %.brd
	eagle -X -d GERBER_RS274X -o $@ $< bPlace bNames bValues

%.GTS: %.brd
	eagle -X -d GERBER_RS274X -o $@ $< tStop

%.GBS: %.brd
	eagle -X -d GERBER_RS274X -o $@ $< bStop

%.GML: %.brd
	eagle -X -d GERBER_RS274X -o $@ $< Milling

%.TXT: %.brd
	eagle -X -d EXCELLON_24 -o $@ $< Drills Holes

%.OLN: %.brd
	eagle -X -d GERBER_RS274X -o $@ $< Dimension

%_gerber.zip: %.GTL %.GBL %.GTO %.GTP %.GBO %.GTS %.GBS %.GML %.TXT %.png %_back.png
	zip $@ $^ $*.dri $*.gpi 
	rm -f $*.dri $*.gpi

%.png: %.dxf
	dxf2png $@

%.png: %.TXT %.GTO %.GTS %.GTL
	gerbv $(GERBV_OPTIONS) --output=$@ \
        --f=$(HOLES_COLOR) $*.TXT \
        --f=$(SILKSCREEN_COLOR) $*.GTO \
        --f=$(PADS_COLOR) $*.GTS \
        --f=$(TOP_SOLDERMASK_COLOR) $*.GTL
	convert $@ -alpha set -fill none -draw 'matte 0,0 floodfill' \( +clone -alpha extract -negate -morphology EdgeIn Diamond -negate -transparent white \) -background none -flatten -trim +repage $@

%_back.png: %.TXT %.GBO %.GBS %.GBL
	gerbv $(GERBV_OPTIONS) --output=$@ \
        --f=$(HOLES_COLOR) $*.TXT \
        --f=$(SILKSCREEN_COLOR) $*.GBO \
        --f=$(PADS_COLOR) $*.GBS \
        --f=$(TOP_SOLDERMASK_COLOR) $*.GBL
	convert $@ -alpha set -fill none -draw 'matte 0,0 floodfill' -flop \( +clone -alpha extract -negate -morphology EdgeIn Diamond -negate -transparent white \) -background none -flatten -trim +repage $@

%.md: %.png %_back.png %.GTL
	echo "## $* \n\n" >  $@
	gerber_board_size $*.GTL >> $@
	echo "\n\n| Front | Back |\n| --- | --- |\n| ![Front]($*.png) | ![Back]($*_back.png) |\n\n" >>  $@

.gitignore:
	echo "\n*~\n.*.swp\n*.?#?\n.*.lck\n.github" >> $@

.git:
	git init
	git add . --all
	git commit -am 'first commit'

.github: | .git
	curl -H "Authorization: token $(github_token)" -o .github https://api.github.com/orgs/$(github_org)/repos -d "{\"name\": \"$(current_dir)\", \"description\": \"$(current_dir)\", \"private\": false, \"has_issues\": true, \"has_downloads\": true, \"has_wiki\": false}"
	git remote add origin git@github.com:$(github_org)/$(current_dir).git
	git push -u origin master

push: .github .gitignore $(boards) $(schematics) $(drawings) $(gerbers) README.md Makefile
	git add . --all
	git commit -am 'from Makefile'
	git push
	touch push

Intro.md:
	touch Intro.md

clean_gerbers:
	rm -f *.G[TBM][LOPS] *.TXT *.dri *.gpi

clean_temps: 
	rm -f *.[bs]#?

clean_pngs:
	rm -f *.png

clean_zips:
	rm -f *.zip

clean_mds:
	rm -f $(mds) README.md

clean: clean_gerbers clean_temps

clean_all: clean_gerbers clean_temps clean_pngs clean_zips clean_mds

info:
	echo $(github_user)



#  # Get user input
#  read "REPONAME?New repo name (enter for ${PWD##*/}):"
#  read "USER?Git Username (enter for ${GITHUBUSER}):"
#  read "DESCRIPTION?Repo Description:"
#  
#  echo "Here we go..."
#  
#  # Curl some json to the github API oh damn we so fancy
#  
#  # Set the freshly created repo to the origin and push
#  # You'll need to have added your public key to your github account
#  git remote set-url origin git@github.com:${USER:-${GITHUBUSER}}/${REPONAME:-${CURRENTDIR}}.git
#  git push --set-upstream origin master

all: bind01.png bind01-spine.png

%.png: %.dot
	dot $< | gvpr -c -ftree.gv | neato -n -Tpng -o $@

clean:
	rm -f *.png

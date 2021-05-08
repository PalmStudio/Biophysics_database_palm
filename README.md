# Ecotron 2021

petit paragraphe pas trop long qui édcrit le projet, regroupe les donénes mesurées à lécotron et fait en préttt pour une base de données commune.


Describe the folders and files structure (use tree).
0-raw = données brutes etc


To do:

- [ ] Ask Sebastien why no climatic data 30/04/2021 between 17h10 and 18h10? Idem on 26/04/2021 between 12h44 and 12h55.
- [ ] Sort the thermal images in different folders according to consecutive periods of time where the plant doesn't move,
and move the ones we don't want into a "backup" folder.
- [ ] Make masks for leaves for each consecutive thermal images
- [ ] compute the mean, median, max and min leaf temperature in the masks (use Julia). And put that in a new file for leaves temp.
- [ ] Reconstruct the plants in 3d:
  - [ ] Separate each leaf and make a mesh for it. Then identify it and name it accordingly.
  - [ ] Make an OPF for each plant from this collection of leaf meshes, using them as ref. meshes with no transformation
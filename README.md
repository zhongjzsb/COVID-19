# COVID-19

Visualizing and modeling the 2019-nCoV is the main objective here. The data are coming from [JHU CSSE](https://github.com/CSSEGISandData/COVID-19) (Old website is [JHU nCov](https://systems.jhu.edu/research/public-health/ncov/)).

As I don't know anything about javascript, so I'm trying to use R to implement this idea. So the initial idea was to create an animated map with dots.

![animate_china](./static/images/china_confirmed.gif)

![animate_world](./static/images/world_confirmed.gif)


![animate_china](./static/images/china_current.gif)

![animate_world](./static/images/world_current.gif)


Then I come into this [github](https://github.com/globalcitizen/2019-wuhan-coronavirus-data/) and created similar plot within R.

![china_polygon_animate](./figures/china_polygon_confirmed.gif)


## Todo:

1. Modelling the data with SIR?
2. Create leaflet map plot with time-series?
3. Plotly?

## References:
- [JHU CSSE](https://systems.jhu.edu/research/public-health/ncov/)
- [2019-wuhan-ncov](https://github.com/globalcitizen/2019-wuhan-coronavirus-data/)
- [some blog](http://boazsobrado.com/blog/2019/01/13/where-i-was-in-2018/)
- [changing-ggplot-geom-sf-choropleth-fill-color](https://stackoverflow.com/questions/48288183/changing-ggplot-geom-sf-choropleth-fill-colors)
- [ggplot2-sf](https://www.r-spatial.org/r/2018/10/25/ggplot2-sf.html)
- [cn-cities](https://simplemaps.com/data/cn-cities)
- [convert-some-column-classes-in-data-table](https://stackoverflow.com/questions/32940580/convert-some-column-classes-in-data-table)

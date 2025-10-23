#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed May 28 12:12:51 2025

@author: juanperez
"""

#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed May 21 21:44:32 2025

@author: juanperez
"""

##############################################################################
###### saving coordinates as geodataframe 


import os
import geopandas as gpd
import pandas as pd
from shapely.geometry import Point

os.chdir('/Users/juanperez/UFL Dropbox/Juan Perez Jimenez/2.Workspace/Maps/shapefile/')

csv_file = 'COD_cholera_reliefcamps_shp/samples_list_analysis.csv'  # Replace with your CSV file name
df = pd.read_csv(csv_file)

df['geometry'] = df.apply(lambda row: Point(row['lon'], row['lat']), axis=1)
geometry = [Point(xy) for xy in zip(df['lon'], df['lat'])]
gdf = gpd.GeoDataFrame(df, geometry=geometry, crs="EPSG:4326")
gdf.to_file("all_2025_vc_list.geojson", driver="GeoJSON")

##############################################################################
###### saving coordinates as geodataframe 
import geopandas as gpd
import matplotlib.pyplot as plt
import contextily as cx


all_shapefile = 'drc.vc.all_2025/all_2025_vc_list.geojson'   
gdf_camps = gpd.read_file(all_shapefile)

gdf = gdf_camps.to_crs(epsg=3857)

source_colors = {
    'campsite': '#FC7D69',
    'ctc': '#72A6CE',
    'env': '#8EC280'
}

# Create base plot
fig, ax = plt.subplots(figsize=(10, 12))

# Plot each cluster in its own color
for source, color in source_colors.items():
    gdf[gdf['source'] == source].plot(
        ax=ax,
        color=color,
        label=source,
        markersize=80,
        alpha=0.65
    )

cx.add_basemap(
    ax,
    source=cx.providers.CartoDB.Positron,
    zoom=8,
    attribution_size=5
)

# Add legend
ax.legend(title="Source", loc='center left', fontsize=20, title_fontsize=22 )
ax.axis('off')

# Show plot
plt.tight_layout()
plt.savefig("DRC_vc_2024_camps_2.png", bbox_inches='tight', pad_inches=0.1, dpi=500)
plt.show()
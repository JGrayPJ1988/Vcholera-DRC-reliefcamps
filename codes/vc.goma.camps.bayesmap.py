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

os.chdir('/Users/Juan/UFL Dropbox/Juan Perez Jimenez/1.UF/1_EPI/1.Tesis-project-I/Workspace/2025.analysis/maps')

csv_file = 'data_shapefiles/vc-drc-onlycamps.csv'  # Replace with your CSV file name
df = pd.read_csv(csv_file)
camp_df = df[df["source"] == "campsite" ]


camp_df['geometry'] = camp_df.apply(lambda row: Point(row['lon'], row['lat']), axis=1)
geometry = [Point(xy) for xy in zip(camp_df['lon'], camp_df['lat'])]
gdf = gpd.GeoDataFrame(camp_df, geometry=geometry, crs="EPSG:4326")
gdf.to_file("data_shapefiles/camps_list_2.geojson", driver="GeoJSON")

##############################################################################
###### saving coordinates as geodataframe 
import geopandas as gpd
import matplotlib.pyplot as plt


camps_shapefile = 'data_shapefiles/camps_list_2.geojson'   
gdf_camps = gpd.read_file(camps_shapefile)

gdf = gdf_camps.to_crs(epsg=3857)

cluster_colors = {
    'A': '#FF9933',
    'B': '#8E063B',
    'C': '#78A5A1',
    'D': '#AFAFAF',
    'E': '#AD9024'
}

xmin, ymin, xmax, ymax = gdf.total_bounds
xpad = (xmax - xmin) * 0.04
ypad = (ymax - ymin) * 0.60

fig, ax = plt.subplots(figsize=(12, 20))

for cluster, color in cluster_colors.items():
    gdf[gdf['cluster'] == cluster].plot(ax=ax, color=color, label=cluster, markersize=250)

    
for idx, row in gdf.iterrows():
    ax.text(
        row.geometry.x + 40,
        row.geometry.y + 89,
        row['location'],
        fontsize=8,
        color='black',
        alpha=0.9,
        ha='left',
        va='bottom',
        bbox=dict(boxstyle="round,pad=0.2", fc="white", ec="none", alpha=0.9)
    )

ax.set_xlim(xmin - xpad, xmax + xpad)
ax.set_ylim(ymin - ypad, ymax + ypad)

try:
    import contextily as cx
    cx.add_basemap(ax, source=cx.providers.CartoDB.Positron, zoom=13)
except ImportError:
    print("contextily not installed, skipping basemap")

ax.axis('off')
plt.tight_layout()


plt.savefig("spatial-analysis/DRC_campsites_bayes_clusters.png", bbox_inches='tight', pad_inches=0.1, dpi=500)
plt.show()


import geopandas as gpd
import matplotlib.pyplot as plt

camps_shapefile = 'data_shapefiles/camps_list.geojson'   
gdf_camps = gpd.read_file(camps_shapefile)
gdf = gdf_camps.to_crs(epsg=3857)

cluster_colors = {
    'cluster-a': '#FF9933',
    'cluster-b': '#8E063B',
    'cluster-c': '#78A5A1',
    'cluster-d': '#AFAFAF',
    'cluster-e': '#AD9024'
}

xmin, ymin, xmax, ymax = gdf.total_bounds
xpad = (xmax - xmin) * 0.04
ypad = (ymax - ymin) * 0.60

fig, ax = plt.subplots(figsize=(12, 20))

# --- Buffer and plot each cluster ---
for cluster, color in cluster_colors.items():
    cluster_gdf = gdf[gdf['cluster'] == cluster]
    
    # Buffer the combined geometry of the cluster (e.g., 400 meters)
    buffer = cluster_gdf.unary_union.buffer(900)
    
    # Convert to GeoDataFrame for plotting
    buffer_gdf = gpd.GeoDataFrame(geometry=[buffer], crs=gdf.crs)
    
    # Plot buffer with transparency
    buffer_gdf.plot(ax=ax, color=color, alpha=0.2, edgecolor=None)

    # Plot original points
    cluster_gdf.plot(ax=ax, color=color, label=cluster, markersize=250)

# --- Add location labels ---
for idx, row in gdf.iterrows():
    ax.text(
        row.geometry.x + 40,
        row.geometry.y + 89,
        row['location'],
        fontsize=8,
        color='black',
        alpha=0.9,
        ha='left',
        va='bottom',
        bbox=dict(boxstyle="round,pad=0.2", fc="white", ec="none", alpha=0.9)
    )

# --- Set limits and basemap ---
ax.set_xlim(xmin - xpad, xmax + xpad)
ax.set_ylim(ymin - ypad, ymax + ypad)

try:
    import contextily as cx
    cx.add_basemap(ax, source=cx.providers.CartoDB.Positron, zoom=13)
except ImportError:
    print("contextily not installed, skipping basemap")

ax.axis('off')
plt.tight_layout()

plt.savefig("spatial-analysis/DRC_campsites_bayes_clusters_buffer.png", bbox_inches='tight', pad_inches=0.1, dpi=500)
plt.show()



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

os.chdir('/Users/Juan/UFL Dropbox/Juan Perez Jimenez/1.UF/1_EPI/1.Tesis-project-I/Workspace/2025.analysis/maps/')

csv_file = 'data_shapefiles/vc-drc-onlycamps.csv'  # Replace with your CSV file name
df = pd.read_csv(csv_file)
camp_df = df[df["source"] == "campsite" ]


camp_df['geometry'] = camp_df.apply(lambda row: Point(row['lon'], row['lat']), axis=1)
geometry = [Point(xy) for xy in zip(camp_df['lon'], camp_df['lat'])]
gdf = gpd.GeoDataFrame(camp_df, geometry=geometry, crs="EPSG:4326")
gdf.to_file("data_shapefiles/camps_list_2.geojson", driver="GeoJSON")

##############################################################################
###### saving coordinates as geodataframe 

import os
import math
import geopandas as gpd
import matplotlib.pyplot as plt
from matplotlib_scalebar.scalebar import ScaleBar

# ---------------------------
# Config
# ---------------------------
CAMPS_FILE = "data_shapefiles/camps_list_2.geojson"
OUTDIR = "charts"
OUT_BASE = "DRC_Goma_campsites_clusters_3"

CLUSTER_COLORS = {
    "Group-5": "#FF9933",
    "Group-3": "#8E063B",
    "Group-4": "#78A5A1",
    "Group-2": "#AFAFAF",
    "Group-1": "#AD9024",
}
POINT_SIZE = 250                # GeoPandas .plot() markersize units
LABEL_DX, LABEL_DY = 40, 89     # base text offset in projected units
LABEL_BOX = dict(boxstyle="round,pad=0.2", fc="white", ec="none", alpha=0.9)
ADD_LEGEND = False              # set True if you want the legend

# ---------------------------
# Load & prepare data
# ---------------------------
gdf_camps = gpd.read_file(CAMPS_FILE)

# basic sanity checks
required_cols = {"cluster", "location", "geometry"}
missing = required_cols - set(map(str.lower, gdf_camps.columns.str.lower()))
if missing:
    raise ValueError(f"Missing required columns in file: {missing}")

# standardize column casing just in case
cols_lower = {c: c.lower() for c in gdf_camps.columns}
gdf_camps = gdf_camps.rename(columns=cols_lower)

# ensure projected to Web Mercator for basemap + scalebar meters
gdf = gdf_camps.to_crs(epsg=3857)

# enforce cluster order defined by CLUSTER_COLORS and fill missing with 0
cluster_counts = (
    gdf["cluster"]
    .value_counts()
    .reindex(CLUSTER_COLORS.keys(), fill_value=0)
)

xmin, ymin, xmax, ymax = gdf.total_bounds
xpad = (xmax - xmin) * 0.04   # 4% horizontal padding
ypad = (ymax - ymin) * 0.60   # 60% vertical padding (for title/legend/inset)

# ---------------------------
# Figure
# ---------------------------
fig, ax = plt.subplots(figsize=(12, 20))

# draw points by cluster
for cl, color in CLUSTER_COLORS.items():
    subset = gdf[gdf["cluster"] == cl]
    if len(subset):
        subset.plot(ax=ax, color=color, label=cl, markersize=POINT_SIZE, zorder=3)

# slightly smarter text placement:
# offset label based on which quadrant (relative to median x/y) the point sits in
mx, my = gdf.geometry.x.median(), gdf.geometry.y.median()
for _, row in gdf.iterrows():
    gx, gy = row.geometry.x, row.geometry.y
    dx = LABEL_DX if gx <= mx else -LABEL_DX  # flip horizontally right of median
    dy = LABEL_DY if gy <= my else -LABEL_DY  # flip vertically above median
    ax.text(
        gx + dx, gy + dy, str(row["location"]),
        fontsize=8, color="black", alpha=0.95, ha="left", va="bottom",
        bbox=LABEL_BOX, zorder=5
    )

# map extent
ax.set_xlim(xmin - xpad, xmax + xpad)
ax.set_ylim(ymin - ypad, ymax + ypad)

# basemap (optional & safe)
try:
    import contextily as cx
    # if tiles fail (offline / rate-limited), we still keep the plot
    try:
        cx.add_basemap(ax, source=cx.providers.CartoDB.Positron, zoom=13, crs=gdf.crs)
    except Exception as e:
        print(f"Basemap skipped: {e}")
except ImportError:
    print("contextily not installed, skipping basemap")

# inset pie (keeps your cluster order)
inset_ax = fig.add_axes([0.13, 0.457, 0.15, 0.29])  # [left, bottom, width, height]
wedges, texts, autotexts = inset_ax.pie(
    cluster_counts.values,
    labels=cluster_counts.index,
    autopct="%1.1f%%",
    colors=[CLUSTER_COLORS[k] for k in cluster_counts.index],
    textprops={"fontsize": 8}
)
inset_ax.set_title("Groups", fontsize=10)

# scale bar (axis units are meters in EPSG:3857)
scalebar = ScaleBar(
    dx=1, units="m", dimension="si-length",
    location="lower right", length_fraction=0.1,
    scale_loc="bottom", box_alpha=0.1
)
ax.add_artist(scalebar)

# legend toggle
if ADD_LEGEND:
    leg = ax.legend(title="Cluster", loc="upper left", frameon=True, framealpha=0.9)
    leg.get_frame().set_facecolor("white")
else:
    # your original behavior
    leg = ax.legend(title="Cluster")
    if leg:
        leg.remove()

# final polish & export
ax.axis("off")
plt.tight_layout()

os.makedirs(OUTDIR, exist_ok=True)
png_path = os.path.join(OUTDIR, f"{OUT_BASE}.png")
svg_path = os.path.join(OUTDIR, f"{OUT_BASE}.svg")

plt.savefig(png_path, bbox_inches="tight", pad_inches=0.1, dpi=500)
plt.savefig(svg_path, bbox_inches="tight", pad_inches=0.1)
plt.show()

print(f"Saved: {png_path}\n       {svg_path}")


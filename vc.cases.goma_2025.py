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

csv_file = 'data_shapefiles/vc-reported-cases-camps.csv'  # Replace with your CSV file name
df = pd.read_csv(csv_file)
camp_df = df[df["source"] == "campsite" ]

camp_df['geometry'] = camp_df.apply(lambda row: Point(row['lon'], row['lat']), axis=1)
geometry = [Point(xy) for xy in zip(camp_df['lon'], camp_df['lat'])]
gdf = gpd.GeoDataFrame(camp_df, geometry=geometry, crs="EPSG:4326")
gdf.to_file("data_shapefiles/vc-reported-cases-camps.geojson", driver="GeoJSON")

# === MAKING THE MAP === #
import geopandas as gpd
import matplotlib.pyplot as plt
import contextily as cx
from matplotlib.patches import FancyArrowPatch
from shapely.geometry import LineString
import os

# === CONFIG ===
REFERENCE_NAMES = ['Munigi']
OUTPUT_PATH = "charts/DRC_Goma_camps_distance_vectors.png"
ARROW_COLOR = '#7B3014'
MARKER_COLOR = '#FC7D69'
FONT_COLOR = '#474747'
ARROW_WIDTH = 1
ARROW_ALPHA = 0.5
ARROW_STYLE = '->'
MUTATION_SCALE = 10

# === Load and clean data ===
gdf = gpd.read_file('data_shapefiles/vc-reported-cases-camps.geojson').to_crs(epsg=3857)
gdf['source'] = gdf['source'].str.strip().str.lower()
gdf['campsite'] = gdf['campsite'].str.strip()

reference_gdf = gdf[gdf['campsite'].isin(REFERENCE_NAMES)].copy()
newer_gdf = gdf[~gdf['campsite'].isin(REFERENCE_NAMES)].copy()

# === Compute lines, distances, and midpoints ===
def compute_vector(point, ref_gdf):
    dists = ref_gdf.geometry.distance(point)
    idx_min = dists.idxmin()
    ref_point = ref_gdf.loc[idx_min].geometry
    line = LineString([ref_point, point])
    return pd.Series({
        'nearest_reference': ref_gdf.loc[idx_min, 'campsite'],
        'distance_m': dists.min(),
        'line': line,
        'midpoint': line.interpolate(0.5, normalized=True)
    })

newer_gdf = newer_gdf.join(newer_gdf.geometry.apply(lambda p: compute_vector(p, reference_gdf)))

# === Set up plot ===
fig, ax = plt.subplots(figsize=(10, 12))
xmin, ymin, xmax, ymax = gdf.total_bounds
xpad = (xmax - xmin) * 0.04
ypad = (ymax - ymin) * 0.60
ax.set_xlim(xmin - xpad, xmax + xpad)
ax.set_ylim(ymin - ypad, ymax + ypad)

# === Draw arrows ===
for line in newer_gdf['line']:
    x0, y0 = line.coords[0]
    x1, y1 = line.coords[-1]
    arrow = FancyArrowPatch(
        (x0, y0), (x1, y1),
        arrowstyle=ARROW_STYLE,
        color=ARROW_COLOR,
        linewidth=ARROW_WIDTH,
        alpha=ARROW_ALPHA,
        linestyle='--',
        mutation_scale=MUTATION_SCALE
    )
    ax.add_patch(arrow)

# === Plot reference and newer camps ===
marker_sizes_ref = reference_gdf['average'] * 1.5
marker_sizes_new = newer_gdf['average'] * 1.5

reference_gdf.plot(ax=ax, color=MARKER_COLOR, markersize=marker_sizes_ref, alpha=0.8)
newer_gdf.plot(ax=ax, color=MARKER_COLOR, markersize=marker_sizes_new, alpha=0.75)

# === Label camps ===
def label_points(df):
    for x, y, loc in zip(df.geometry.x, df.geometry.y, df['campsite']):
        ax.text(x, y + 650, loc, fontsize=8, ha='center', va='bottom', color=FONT_COLOR, fontweight='bold')

label_points(reference_gdf)
label_points(newer_gdf)

# === Label distances ===
for dist, midpoint in zip(newer_gdf['distance_m'], newer_gdf['midpoint']):
    mx, my = midpoint.x, midpoint.y
    ax.text(mx, my, f"{int(dist)} m", fontsize=7, ha='center', va='center', color=FONT_COLOR)

# === Basemap ===
cx.add_basemap(ax, source=cx.providers.CartoDB.Positron, zoom=13, attribution_size=5)

# === Legend ===
for size in [10, 50, 100]:
    ax.scatter([], [], s=size * 1.5, c=MARKER_COLOR, alpha=0.6, label=f'{size} cases')

ax.legend(title="Confirmed cholera cases", loc='upper left', fontsize=10, title_fontsize=12)
ax.axis('off')
plt.tight_layout()

# === Save plot ===
os.makedirs(os.path.dirname(OUTPUT_PATH), exist_ok=True)
plt.savefig(OUTPUT_PATH, bbox_inches='tight', pad_inches=0.1, dpi=500)
plt.show()

import geopandas as gpd
import pandas as pd
import matplotlib.pyplot as plt
import contextily as cx
from matplotlib.patches import FancyArrowPatch, Patch
from matplotlib.patheffects import withStroke
from shapely.geometry import LineString
from mpl_toolkits.axes_grid1.inset_locator import inset_axes
import os

# === CONFIGURATION ===
REFERENCE_NAMES = ['Munigi']
OUTPUT_PATH = "charts/DRC_Goma_camps_with_pies.png"
ARROW_COLOR = '#665C51'
MARKER_COLOR = '#FC7D69'
FONT_COLOR = '#474747'
PIE_COLORS = {2022: "#FFE082", 2023: "#FFB27D", 2024: "#FF9999"}
MUTATION_SCALE = 10
PIE_SIZE = 0.7
ZOOM = 13
PIE_OFFSET_X = 350
PIE_OFFSET_Y = 100
DISTANCE_LABEL_OFFSET = 0  # Adjust if needed

# === DATA LOADING ===
gdf_raw = gpd.read_file("data_shapefiles/vc-reported-cases-camps.geojson")
gdf_raw['source'] = gdf_raw['source'].str.strip().str.lower()
gdf_raw['campsite'] = gdf_raw['campsite'].str.strip()
gdf_raw = gdf_raw.to_crs(epsg=3857)

# === AGGREGATE PIE DATA ===
gdf_pie = (
    gdf_raw
    .pivot_table(index=['campsite', 'lat', 'lon'], columns='year', values='average', fill_value=0)
    .reset_index()
)
gdf_pie['geometry'] = gpd.points_from_xy(gdf_pie['lon'], gdf_pie['lat'])
gdf_pie = gpd.GeoDataFrame(gdf_pie, geometry='geometry', crs="EPSG:4326").to_crs(epsg=3857)

# === REFERENCE AND TARGET CAMPS ===
gdf_2024 = gdf_raw[gdf_raw['year'] == 2024]
reference_gdf = gdf_2024[gdf_2024['campsite'].isin(REFERENCE_NAMES)]
target_gdf = gdf_2024[~gdf_2024['campsite'].isin(REFERENCE_NAMES)]

# Compute vectors from targets to closest reference
def compute_vector(point, ref_gdf):
    dists = ref_gdf.geometry.distance(point)
    idx_min = dists.idxmin()
    ref_point = ref_gdf.loc[idx_min].geometry
    line = LineString([ref_point, point])
    return pd.Series({
        'nearest_reference': ref_gdf.loc[idx_min, 'campsite'],
        'distance_m': dists.min(),
        'line': line,
        'midpoint': line.interpolate(0.5, normalized=True)
    })

target_gdf = target_gdf.join(target_gdf.geometry.apply(lambda p: compute_vector(p, reference_gdf)))

# === PLOTTING ===
fig, ax = plt.subplots(figsize=(14, 8))

# Set map bounds
xmin, ymin, xmax, ymax = gdf_2024.total_bounds
xpad, ypad = (xmax - xmin) * 0.05, (ymax - ymin) * 0.60
ax.set_xlim(xmin - xpad, xmax + xpad)
ax.set_ylim(ymin - ypad, ymax + ypad)

# --- DRAW ARROWS ---
for line in target_gdf['line']:
    x0, y0 = line.coords[0]
    x1, y1 = line.coords[-1]
    ax.add_patch(FancyArrowPatch(
        (x0, y0), (x1, y1),
        arrowstyle='-',
        color=ARROW_COLOR,
        linewidth=2,
        alpha=0.5,
        linestyle='--',
        mutation_scale=MUTATION_SCALE,
        shrinkA=5, shrinkB=5
    ))

# --- DRAW PIE CHARTS ---
def make_autopct(values):
    def _autopct(pct):
        total = sum(values)
        val = round(pct * total / 100.0, 1)
        return f'{val:.1f}' if val > 0 else ''
    return _autopct

for _, row in gdf_pie.iterrows():
    x, y = row.geometry.x, row.geometry.y
    pie_data = [row.get(year, 0) for year in PIE_COLORS]
    total = sum(pie_data)
    if total == 0:
        continue

    axins = inset_axes(
        ax, width=PIE_SIZE, height=PIE_SIZE, loc='center',
        bbox_to_anchor=(x - PIE_OFFSET_X, y + PIE_OFFSET_Y),
        bbox_transform=ax.transData, borderpad=0
    )

    wedges, texts, autotexts = axins.pie(
        pie_data,
        colors=[PIE_COLORS[year] for year in PIE_COLORS],
        startangle=90,
        wedgeprops={'linewidth': 0.05, 'edgecolor': 'white'},
        autopct=make_autopct(pie_data),
        textprops={'fontsize': 6.5, 'color': 'black', 'weight': 'medium'}
    )
    axins.axis("equal")
    axins.axis("off")

    for autotext in autotexts:
        autotext.set_path_effects([withStroke(linewidth=1, foreground='white')])

# --- CAMP LABELS ---
for _, row in gdf_pie.iterrows():
    ax.text(
        row.geometry.x, row.geometry.y + 560, row['campsite'],
        fontsize=8, ha='right', va='bottom', color=FONT_COLOR, fontweight='bold'
    )

# --- DISTANCE LABELS ---
for dist, midpoint in zip(target_gdf['distance_m'], target_gdf['midpoint']):
    mx, my = midpoint.x, midpoint.y + DISTANCE_LABEL_OFFSET
    ax.text(
        mx, my, f"{dist / 1000:.1f} km",
        fontsize=6.5, ha='left', va='center', color=FONT_COLOR,
        bbox=dict(boxstyle="round,pad=0.2", facecolor='white', edgecolor='gray', linewidth=0.5)
    )

# --- BASEMAP & LEGEND ---
cx.add_basemap(ax, source=cx.providers.CartoDB.Positron, zoom=ZOOM, attribution_size=5)
legend_elements = [Patch(facecolor=color, label=str(year)) for year, color in PIE_COLORS.items()]
ax.legend(handles=legend_elements, title='Average cases per Year', loc='upper left', fontsize=9)

# Finalize
ax.axis('off')
plt.tight_layout()

# --- SAVE FIGURE ---
os.makedirs(os.path.dirname(OUTPUT_PATH), exist_ok=True)
plt.savefig(OUTPUT_PATH, dpi=500, bbox_inches='tight', pad_inches=0.1)
plt.show()

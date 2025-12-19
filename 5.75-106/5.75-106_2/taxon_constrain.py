#! /usr/bin/env/python

import pandas as pd
import numpy as np
import glob
import argparse
import os
import re
from sys import exit
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('gaf')
parser.add_argument('obo')
parser.add_argument('union')
parser.add_argument('lineage', type=str)
parser.add_argument('outdir')
args = parser.parse_args()
gaf = args.gaf # GAF file annotations to apply taxon constraints to
obo = args.obo # taxon constraints .obo file found here: https://current.geneontology.org/ontology/imports/go-computed-taxon-constraints.obo
union = args.union # taxon groupings .obo file found here: https://current.geneontology.org/ontology/imports/go-taxon-groupings.obo
lineage = args.lineage # list of taxon ids representing the taxonomic lineage of the species annotated (use taxonkit to get this)
outdir = args.outdir # (default is '.') directory where outputs from this will go
pd.set_option('display.max_columns', None)

#USE LINEAGE ARRAY TO CREATE LIST
lin = lineage.split(sep=",")
#CREATE DATAFRAME FROM GAF FILE
gaf_df = pd.read_table(f"{gaf}", dtype=str)
#CREATE DATAFRAME FROM OBO FILE
stanzas = []
current_stanza = None
with open(outdir + '/' + 'constraints.obo', 'r', encoding='utf-8') as f:
    for line in f:
        line = line.strip()
        if line.startswith('!'):
            continue  # Ignore comments
        if not line:
            continue  # Ignore blank lines
        if line.startswith('['):
            # Start of a new stanza
            if current_stanza:
                stanzas.append(current_stanza)
            current_stanza = {'type': line[1:-1], 'tags': {}}
        else:
            # Tag-value pair within a stanza
            if current_stanza:
                if ':' in line:
                    tag, value_with_comment = line.split(':', 1)
                    tag = tag.strip()
                    value = value_with_comment.split('!', 1)[0].strip() # Remove trailing comments
                    if tag in current_stanza['tags']:
                        # Handle multiple values for the same tag (e.g., property_value)
                        if isinstance(current_stanza['tags'][tag], list):
                            current_stanza['tags'][tag].append(value)
                        else:
                            current_stanza['tags'][tag] = [current_stanza['tags'][tag], value]
                    else:
                        current_stanza['tags'][tag] = value
if current_stanza:
    stanzas.append(current_stanza)
# Process obo stanzas into a structured format for pandas
data_for_df = []
for stanza in stanzas:
    if stanza['type'] == 'Term':
        term_data = {'id': stanza['tags'].get('id', ''), 'is_obsolete': stanza['tags'].get('is_obsolete', 'false')}
        # Extract taxon constraints from 'property_value' tags
        prop_values = stanza['tags'].get('property_value', [])
        if isinstance(prop_values, str):
            prop_values = [prop_values]
        for pv_str in prop_values:
            # Format is typically "RO:0002161 NCBITaxon:40674"
            match = re.search(r'(RO:\d+)\s+(NCBITaxon:\d+|NCBITaxon_Union:\d+)', pv_str)
            if match:
                term_data['taxon_relationship'] = match.group(1)
                term_data['taxon_id'] = match.group(2)
                # Add to data list (one row per term and constraint)
                data_for_df.append(term_data.copy())
            else:
                # Append term even if no explicit taxon constraint is found in property_value
                data_for_df.append(term_data.copy())
        # Extract taxon constraints from 'relationship' tags
        relationship = stanza['tags'].get('relationship', [])
        if isinstance(relationship, str):
            relationship = [relationship]
        for rt_str in relationship:
            # Format is typically "RO:0002162 NCBITaxon:40674"
            match = re.search(r'(RO:\d+)\s+(NCBITaxon:\d+|NCBITaxon_Union:\d+)', rt_str)
            if match:
                term_data['taxon_relationship'] = match.group(1)
                term_data['taxon_id'] = match.group(2)
                # Add to data list (one row per term and constraint)
                data_for_df.append(term_data.copy())
            else:
                # Append term even if no explicit taxon constraint is found in property_value
                data_for_df.append(term_data.copy())
# Create the pandas DataFrame
obo_df = pd.DataFrame(data_for_df)

#CREATE DATAFRAME FROM UNIONS OBO FILE
stnzas = []
current_stnza = None
with open(outdir + '/' + 'unions.obo', 'r', encoding='utf-8') as file:
    for line in file:
        line = line.strip()
        if line.startswith('!'):
            continue  # Ignore comments
        if not line:
            continue  # Ignore blank lines

        if line.startswith('['):
            # Start of a new stanza
            if current_stnza:
                stnzas.append(current_stnza)
            current_stnza = {'type': line[1:-1], 'tags': {}}
        else:
            # Tag-value pair within a stanza
            if current_stnza:
                if ':' in line:
                    tag, value_with_comment = line.split(':', 1)
                    tag = tag.strip()
                    value = value_with_comment.split('!', 1)[0].strip()  # Remove trailing comments
                    if tag in current_stnza['tags']:
                        # Handle multiple values for the same tag (e.g., property_value)
                        if isinstance(current_stnza['tags'][tag], list):
                            current_stnza['tags'][tag].append(value)
                        else:
                            current_stnza['tags'][tag] = [current_stnza['tags'][tag], value]
                    else:
                        current_stnza['tags'][tag] = value

if current_stnza:
    stnzas.append(current_stnza)

# Process union stanzas into a structured format for pandas
data_for_udf = []
for stnza in stnzas:
    if stnza['type'] == 'Term':
        term_data = {
            'id': stnza['tags'].get('id', ''),
            'is_obsolete': stnza['tags'].get('is_obsolete', 'false'),
            'is_a': [],
            'disjoint_from': [],
            'union_of': []
        }

        # Helper function to extract and store taxon IDs
        def extract_taxons(tag_value, target_list):
            if isinstance(tag_value, str):
                tag_value = [tag_value]
            for item_str in tag_value:
                # Regex just needs one group, we use group(1)
                match = re.search(r'(NCBITaxon:\d+|NCBITaxon_Union:\d+)', item_str)
                if match:
                    target_list.append(match.group(1))

        extract_taxons(stnza['tags'].get('is_a', []), term_data['is_a'])
        extract_taxons(stnza['tags'].get('disjoint_from', []), term_data['disjoint_from'])
        extract_taxons(stnza['tags'].get('union_of', []), term_data['union_of'])

        data_for_udf.append(term_data)

# Create the pandas DataFrame
union_df = pd.DataFrame(data_for_udf)

# Convert lists to strings for better TSV representation
for col in ['is_a', 'disjoint_from', 'union_of']:
    union_df[col] = union_df[col].apply(lambda x: ', '.join(x) if isinstance(x, list) else x)

#ADD HEADERS TO GAF_DF
gaf_df.columns = ['Database', 'DB_Object_ID', 'DB_Object_Symbol', 'Qualifier', 'GO_ID', 'DB_Reference', 'Evidence_Code', 'With_From', 'Aspect', 'DB_Object_Name', 'DB_Object_Synonyms', 'DB_Object_Type', 'Taxon', 'Date', 'Assigned_By', 'Annotation_Extension', 'Gene_Product_Form_Id']

#REMOVE UNION_DF LINES FOR NCBITAXON_UNION AND LEAVE NCBITAXON LINES
mask = union_df['id'].str.contains('NCBITaxon_Union', na=False)
union_df = union_df[~mask]

#DROP UNION_OF COL FROM UNION DF (ONLY APPLIED TO NCBITAXON_UNION TERMS THAT WE GOT RID OF
union_df.drop(['union_of'], axis=1, inplace=True)

#EXPLODE IS A AND DISJOINT FROM COLUMNS
union_df['disjoint_from'] = union_df['disjoint_from'].str.split(',')
union_df = union_df.explode('disjoint_from')

union_df['is_a'] = union_df['is_a'].str.split(',')
union_df = union_df.explode('is_a')


#NEED TO REMOVE 'NCBITAXON:' PREFIXES IN OBO DF
obo_df['taxon_id'] = obo_df['taxon_id'].str.replace('NCBITaxon:', '')
obo_df['taxon_id'] = obo_df['taxon_id'].str.replace('NCBITaxon_Union:', '')

#REMOVE NCBITAXON PREFIXES FROM UNION DF
union_df['id'] = union_df['id'].str.replace('NCBITaxon:', '')
union_df['is_a'] = union_df['is_a'].str.replace('NCBITaxon:', '')
union_df['disjoint_from'] = union_df['disjoint_from'].str.replace('NCBITaxon:', '')
union_df['id'] = union_df['id'].str.replace('NCBITaxon_Union:', '')
union_df['is_a'] = union_df['is_a'].str.replace('NCBITaxon_Union:', '')
union_df['disjoint_from'] = union_df['disjoint_from'].str.replace('NCBITaxon_Union:', '')


#MERGE GAF AND OBO ON GO:IDS
gaf_obo = pd.merge(gaf_df, obo_df, left_on='GO_ID', right_on='id', how='outer')

#DELETE ROWS FROM GAF_OBO WHERE DB_OBJECT_ID IS EMPTY (NAN)--LEAVES ONLY TAXON CONSTRAINTS THAT ARE ACTUALLY RELATED TO THESE ANNOTATIONS
gaf_obo['DB_Object_ID'] = gaf_obo['DB_Object_ID'].replace('', np.nan)
gaf_obo = gaf_obo.dropna(subset=['DB_Object_ID'])

#DROP ID AND OBSOLETE FROM GAF OBO
gaf_obo.drop(['id', 'is_obsolete'], axis=1, inplace=True)

#MERGE GAF_OBO TO UNIONS
gaf_obo = pd.merge(gaf_obo, union_df, left_on='taxon_id', right_on='id', how='left')

#ADD RELATED TAXON UNIONS TO THE LIN LIST
union_df['is_a'] = union_df['is_a'].replace('', np.nan)
union_df['disjoint_from'] = union_df['disjoint_from'].replace('', np.nan)
union_isa_df = union_df.dropna(subset=['is_a'])
for index, row in union_isa_df.iterrows():
    if row['id'] in lin:
        lin.append(row['is_a'])

#MOVE LINES THAT DONT' HAVE ANY OBO CONSTRAINTS FROM GAF_OBO TO NEW_KEEP_GAF
#NEW GAF AFTER THIS SHOULD HAVE ONLY LINES THAT ARE MISSING OBO INFO
#GAF_OBO SHOULD BE MISSING ALL OF THE LINES THAT ARE IN NEW GAF
new_keep_gaf = pd.DataFrame(columns=gaf_obo.columns)
gaf_obo[['taxon_id', 'is_a', 'disjoint_from']] = gaf_obo[['taxon_id', 'is_a', 'disjoint_from']].replace('', np.nan)
mask = gaf_obo['taxon_id'].notna()

new_keep_gaf = pd.concat([new_keep_gaf, gaf_obo[~mask]], ignore_index=True)
gaf_obo = gaf_obo[mask].reset_index(drop=True)

#IF RELATIONSHIP IS 62 AND TAXON_ID IS IN LIN ADD LINE TO NEW KEEP GAF
#AFTER THIS STEP  NEW KEEP GAF SHOULD HAVE MORE LINES THAN BEFORE AND ALL NEW LINES SHOULD HAVE ro:#62 AND THOSE TAXON IDS SHOULD BE IN LIN
#GAF OBO SHOULD BE MISSING THE SAME LINES AS WERE ADDED TO NEW KEEP GAF
mask2 = (gaf_obo['taxon_relationship'] == 'RO:0002162') & (gaf_obo['taxon_id'].isin(lin))
new_keep_gaf = pd.concat([new_keep_gaf, gaf_obo[mask2]], ignore_index=True)
gaf_obo = gaf_obo[~mask2].reset_index(drop=True)


#IF RELATIONSHIP IS 62 AND TAXON_ID IS not IN LIN ADD LINE TO CONSTRAINED GAF
#AFTER THIS GAF_OBO SHOULDN'T CONTAIN ANY ro62 LINES
#CONSTRAINED GAF SHOULD CONTAIN ONLY RO:62 WITH TAXIDS THAT DON'T MATCH LIN
constrained_gaf = pd.DataFrame(columns=gaf_obo.columns)
mask3 = (gaf_obo['taxon_relationship'] == 'RO:0002162') & (~gaf_obo['taxon_id'].isin(lin))
constrained_gaf = pd.concat([constrained_gaf, gaf_obo[mask3]], ignore_index=True)
gaf_obo = gaf_obo[~mask3].reset_index(drop=True)

#IF RELATIONSHIP IS 61 AND TAXON_ID IS IN LIN ADD LINE TO CONSTRAINED GAF
#AFTER THIS CONSTRAINED SHOULD ALSO CONTAIN RO61 LINES WITH TAXON IDS IN LIN; IF ANY ANNOTATIONS ARE CONSTRAINED
#THESE LINES SHOULD BE MISSING FROM GAF_OBO
mask4 = (gaf_obo['taxon_relationship'] == 'RO:0002161') & (gaf_obo['taxon_id'].isin(lin))
constrained_gaf = pd.concat([constrained_gaf, gaf_obo[mask4]], ignore_index=True)
gaf_obo = gaf_obo[~mask4].reset_index(drop=True)


#IF RELATIONSHIP IS 61 AND TAXON_ID IS not IN LIN ADD LINE TO CONSTRAINED GAF
#AFTER THIS CONSTRAINED SHOULD ALSO CONTAIN RO61 LINES WITH TAXON IDS IN LIN; IF ANY ANNOTATIONS ARE CONSTRAINED
#THESE LINES SHOULD BE MISSING FROM GAF_OBO
mask5 = (gaf_obo['taxon_relationship'] == 'RO:0002161') & (~gaf_obo['taxon_id'].isin(lin))
new_keep_gaf = pd.concat([new_keep_gaf, gaf_obo[mask5]], ignore_index=True)
gaf_obo = gaf_obo[~mask5].reset_index(drop=True)


#REMOVE EXCESS COLUMNS FROM NEW GAF, REMOVE DUPS  AND PRINT
new_keep_gaf.drop(['disjoint_from', 'is_a', 'is_obsolete', 'id', 'taxon_id', 'taxon_relationship'], axis=1, inplace=True)
new_keep_gaf = new_keep_gaf.drop_duplicates()
new_keep_gaf.to_csv(outdir + '/' + "new_keep_gaf.tsv", sep='\t', header=False, index=False)

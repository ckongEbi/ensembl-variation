#
# variation
#
# Central table containing actual variations (indels, SNPs etc.)  
#

# variation_id        - primary key, internal identifier
# source_id           - foreign key ref source
# name                - identifier for the variation such as the dbSNP
#                       refSNP id (rs#) or SubSNP id (ss#)

create table variation (
	variation_id int not null auto_increment, # PK
	source_id int not null, 
	name varchar(255),
	validation_status SET('cluster','freq','submitter','doublehit','hapmap'),

	primary key( variation_id ),
	unique ( name )
);


#
# variation_synonym
#
# Table containing alternate identifiers for the same variation.
# For example this might be subsnp identifiers for the refsnp.
#
#

create table variation_synonym (
  variation_synonym_id int not null auto_increment,
  variation_id int not null,
  source_id int not null,
  name varchar(255),

  primary key(variation_synonym_id),
  key variation_idx (variation_id),
  unique (name, source_id)
);


#
# population_synonym
#
# Table containing alternate identifiers for the same population.
# For example this might be pop_id identifiers for the population in dbSNP.
#
#

create table population_synonym (
  population_synonym_id int not null auto_increment,
  population_id int not null,
  source_id int not null,
  name varchar(255),

  primary key(population_synonym_id),
  key population_idx (population_id),
  unique (name, source_id)
);



#
# allele
#
# Every allele for every variation in the database has a row in this table.
# Alleles are repeated in this table as often as necessary.  For example
# a variation may have alleles 'A' and 'T'. This would be represented by
# two rows in this table.  A different variation which also had an 'A'
# allele would require another row in this table. This way it is 
# simple to track frequency and population for each allele and hopefully not 
# too much space is wasted on the actual allele strings.
#

# allele_id     - primary key, internal identifier
# variation_id  - foreign key ref variation
# allele        - string representing an allele.  E.g. 'A', 'T'
# frequency     - the frequency of this allele in population 
# population_id - foreign key ref population

create table allele(
	allele_id int not null auto_increment,
	variation_id int not null,
	allele text,
	frequency float,
	population_id int,

	primary key( allele_id ),
	key variation_idx( variation_id,allele(10) )
);


#
# population
#
# A population may be an ethnic group (e.g. caucasian, hispanic), assay group (e.g. 24 europeans),
# strain, phenotypic group (e.g. blue eyed, diabetes) etc. 
# Populations may be composed of other populations by defining relationships in the 
# population_structure table.
#

# population_id        - primary key, internal identifier
# name                 - name or identifier of the population
# size                 - if the size is NULL its not known or not relevant for this population
#                        eg. "european" would not have a size 
# is_strain            - int, 1 means that the population is a strain, 0 otherwise

create table population(
	population_id int not null auto_increment,
	name varchar(255) not null,
	size int,
	description text,
	is_strain int(1) default 0 NOT NULL,

	primary key( population_id ),
  unique name_idx( name )
);



#
# population_structure
#
# Defines sub/super population relationships.  For example an assay used to determine
# allele frequency may be represented by a superpopulation of caucasions and a sub population 
# of the group of people used in the assay.
#
create table population_structure (
  super_population_id int not null,
  sub_population_id int not null,

  unique(super_population_id, sub_population_id),
  key sub_pop_idx (sub_population_id, super_population_id)
);


#
# individual
#
# Table containing individuals.  An individual is a single member of a population.
#
#  individual            - PK, unique internal identifier
#  name                  - name of individual
#  population_id         - the population that this individual is a member of
#  gender                - the sex of this individual
#  father_individual_id  - self referential id, the father of this individual if known
#  mother_individual_id  - self referential id, the mother of this individual if known
#  
#

create table individual(
  individual_id int not null auto_increment,
  name varchar(255) not null,
  description varchar(255) not null,
  population_id int not null,
  gender enum('Male', 'Female', 'Unknown') default 'Unknown' NOT NULL,
  father_individual_id int,
  mother_individual_id int,
  
  primary key(individual_id),
  key population_idx (population_id),
  key name_idx (name)
);




#
# variation_feature
#
# This is a feature table similar to the feature tables in the core database.
# The seq_region_id references a seq_region in the core database and the
# seq_region_start, seq_region_end and seq_region_strand represent a 
# variation position on that seq_region.  This table incorporates some 
# denormalisation, taking fields from other tables so that information
# needed for feature creation can be quickly retrieved.
#
# variation_feature_id  - primary key, internal identifier
# seq_region_id         - foreign key references seq_region in core db
#                         This refers to the seq_region which this snp is
#                         on, which may be a chromosome or clone etc.
# seq_region_start      - the start position of the variation on the seq_region
# seq_region_end        - the end position of the variation on the seq_region
# seq_region_strand     - the orientation of the variation on the seq_region
# variation_id          - foreign key refs variation, the variation associated
#                         with this position
# allele_string         - this is a denormalised string taken from the 
#                         alleles in the allele table associated with this
#                         variation.  The reference allele (i.e. one on the
#                         reference genome comes first).
# variation_name        - a denormalisation taken from the variation table
#                         this is the name or identifier that is used for
#                         displaying the feature.
# map_weight            - the number of times that this variation has mapped 
#                         to the genome.  This is a denormalisation as this
#                         particular feature is one example of a mapped 
#                         location.  This can be used to limit the 
#                         the features that come back from a query.
# flags                 - possible values genotyped, to filter the selection of
#			  variations


create table variation_feature(
	variation_feature_id int not null auto_increment,
	seq_region_id int not null,
	seq_region_start int not null,
	seq_region_end int not null,
	seq_region_strand tinyint not null,
	variation_id int not null,
	allele_string text,
	variation_name varchar(255),
	map_weight int not null,
	flags SET('genotyped'),
	source_id int not null, 
	validation_status SET('cluster','freq','submitter','doublehit','hapmap'),
	consequence_type enum( "INTRONIC", "UPSTREAM", "DOWNSTREAM", "SYNONYMOUS_CODING",
		           "NON_SYNONYMOUS_CODING", "FRAMESHIFT_CODING", 
             	"5PRIME_UTR", "3PRIME_UTR", "INTERGENIC" ) default "INTERGENIC" not null ,	

	primary key( variation_feature_id ),
	key pos_idx( seq_region_id, seq_region_start ),
	key variation_idx( variation_id )
);


#
# variation_group
# 
# This table defines a variation group.  Allele groups can 
# be classed into a variation_group when they are comprised
# of the same set of variations.  This is equivalent to 
# HapSets in dbSNP.
#
# variation_group_id   - primary_key, internal identifier
# name                 - the code or name of this variation_group
# source_id            - foreign key ref source
#

create table variation_group (
	variation_group_id int not null auto_increment,
	name varchar(255),
	source_id int not null,
  type enum('haplotype', 'tag'),

	primary key (variation_group_id),
  unique(name)
);

#
# variation_group_feature
# Keeps all the variations stored in a group (normalisation of the n..n relationship between variation and variation_group)
# variation_id - foreign key references variation
# variation_group_id - foreign key references variation_group
#

create table variation_group_variation (
	variation_id int not null,
	variation_group_id int not null,

	unique( variation_group_id, variation_id ),
	key variation_idx( variation_id, variation_group_id )
);

#
# variation_group_feature
#
# Places a variation_group (i.e. group of associated haplotypes) on the genome
# as a feature.
#
# variation_group_feature_id - primary key, internal identifier
# seq_region_id              - foreign key references seq_region in core db
# seq_region_start           - start position of the variation_group_feature
#                              on the referenced seq_region
# seq_region_end             - end position of the variation_group_feature
# seq_region_strand          - orientation of feature on seq_region
# variation_group_id         - foreign key references variation_group
#

create table variation_group_feature(
  variation_group_feature_id int not null auto_increment,
  seq_region_id int not null,
  seq_region_start int not null,
  seq_region_end int not null,
  seq_region_strand tinyint not null,
  variation_group_id int not null,
  variation_group_name varchar(255),

  primary key (variation_group_feature_id),
  key pos_idx(seq_region_id, seq_region_start),
  key variation_group_idx(variation_group_id)
);

#
# transcript_variation
# 
# This table contains a classification of variation features based on Ensembl
# predicted transcripts.  Variation features which fall into Ensembl 
# transcript regions are classified as 'INTRONIC', '5PRIME', '3PRIME',
# 'SYNONYMOUS_CODING', 'NON_SYNONYMOUS_CODING', 'FRAMESHIFT_CODING',
# '5PRIME_UTR', '3PRIME_UTR'
#
# transcript_variation_id - primary key, internal identifier
# transcript_id           - foreign key to core databases
#                           unique internal id of related transcript
# variation_feature_id    - foreign key ref variation_feature
# cdna_start              - start position of variation in cdna coordinates
# cdna_end                - end position of variation in cdna coordinates
# translation_start       - start position of variation on peptide
# translation_end         - end position of variation on peptide
# peptide_allele_string   - allele string of '/' separated amino acids
# consequence_type        - reference allele is first
# 

create table transcript_variation(
	transcript_variation_id int not null auto_increment,
  transcript_id int not null,
	variation_feature_id int not null,
  cdna_start int,
  cdna_end   int,
  translation_start int,
  translation_end int,  
  peptide_allele_string varchar(255),
  consequence_type enum( "INTRONIC", "UPSTREAM", "DOWNSTREAM", "SYNONYMOUS_CODING",
	           "NON_SYNONYMOUS_CODING", "FRAMESHIFT_CODING", 
             "5PRIME_UTR", "3PRIME_UTR" ) not null,
	
  primary key( transcript_variation_id ),
  key variation_idx( variation_feature_id ),
  key transcript_idx( transcript_id ),
  key consequence_type_idx(consequence_type)
	);
	

#
# allele_group
#
# This table defines haplotypes - groups of
# polymorphisms which are found together in a block.
# This is equivalent to Haps in dbSNP
#
# allele_group_id    - primary_key, internal identifier
# variation_group_id - foreign key, ref variation_group
# population_id      - foreign key, ref population
# name               - the name of this allele group
# frequency          - the frequency of this allele_group
#                      within the referenced population
#
#

create table allele_group(
	allele_group_id int not null auto_increment,
	variation_group_id int not null,
	population_id int,
	name varchar(255),
	source_id int,
	frequency float,

	primary key( allele_group_id ),
  unique(name)
);


#
# allele_group_allele
#
# Defines which alleles make up an allele group.  
# There is no direct link to the allele table because the allele table has 
# population and frequency data which may not correspond to this allele group
#
# allele_group_id - primary key, internal identifier
# allele - base present in the group
# variation_id - foreign key, references variation

create table allele_group_allele (
	allele_group_id int not null,
	allele varchar(255) not null,
        variation_id int not null,

	unique( allele_group_id, variation_id ),
	key allele_idx( variation_id, allele_group_id )
);


#
# flanking_sequence
#
# table that stores the flanking sequences from th core database. To reduce space used, takes coordinates from the sequences in the core database
# variation_id - primary key, internal identifier
# up_seq - upstream sequence, used to initially store the sequence from the core database, and in a later process get from here the position
# down_seq - similiar the one before, but for the downstream
# up_seq_region_start, down_seq_region_start - position of the starting of the sequence in the region
# up_seq_region_end, down_seq_region_end - position of the end of the sequence in the region
# seq_region_id - foreign key, references the sequence table in the core database
# seq_region_stran - strand of the seq_region in the core database
#

create table flanking_sequence (
	variation_id int not null,
	up_seq text,
	down_seq text,
  up_seq_region_start int,
  up_seq_region_end   int,
  down_seq_region_start int,
  down_seq_region_end int,
  seq_region_id int,
  seq_region_strand tinyint,

	primary key( variation_id )

) MAX_ROWS = 100000000;


#
# httag
#
# this table contains the tags of a haplotype: bases of the haplotypes that uniquely identify it
#
# httag_id - primary key, internal identifier
# variation_group_id - foreign key, references variation_group
# name - name of the tag, for web purposes
# source_id - foreign key, references source
#

create table httag(
	httag_id int not null auto_increment,
	variation_group_id int not null,
	name varchar(255),
	source_id int not null,

	primary key( httag_id ),
	key variation_group_idx( variation_group_id )
);

#
# source
#
# this table contains sources of snps. this might be dbSNP, TSC, HGBase, etc. 
#
# source_id - primary key, internal identifier
# name      - the name of the source.  e.g. 'dbSNP' 

create table source(
	source_id int not null auto_increment,
	name varchar(255),
	version int,
	
	primary key( source_id )
);



#
# population_genotype
#
# This table contains genotype frequencies estimated for populations or calculated on
# a set of individuals.
#
# population_genotype_id - primary key, internal identifier
# variation_id - foreign key, references variation table
# allele_1 - first allele in the genotype
# allele_2 - second allele in the genotype
# frequency - frequency of the genotype in the population
# population_id - foreign key, references population table
#

create table population_genotype (
	population_genotype_id int not null auto_increment,
	variation_id int not null,
	allele_1 varchar(255),
	allele_2 varchar(255),
	frequency float,
 	population_id int,

	primary key( population_genotype_id ),
 	key variation_idx(variation_id),
	key population_idx(population_id)
);



#
# individual_genotype_single_bp
#
# This table contains genotypes of individuals with 1 single bp in the alleles.
#
# variation_id	- FK to variation table
# allele_1	- One of the alleles of the genotype
# allele_2	- The other allele of the genotype
# individual_id - foreign key, references individual table

create table individual_genotype_single_bp (
  variation_id int not null,
  allele_1 char,
  allele_2 char,
  individual_id int,

  key variation_idx(variation_id),
  key individual_idx(individual_id)
) MAX_ROWS = 100000000;

#
# individual_genotype_multiple_bp
#
# This table contains genotypes of individuals with more than 1 bp in the alleles.
#
# variation_id	- FK to variation table
# allele_1	- One of the alleles of the genotype
# allele_2	- The other allele of the genotype
# individual_id - foreign key, references individual table

create table individual_genotype_multiple_bp (
  variation_id int not null,
  allele_1 varchar(255),
  allele_2 varchar(255),
  individual_id int,

  key variation_idx(variation_id),
  key individual_idx(individual_id)
);

#
# pairwise_ld
# this table contains ld values for 2 SNPs in a certain population
#
# variation_feature_id_1 - FK, references variation_feature table
# variation_feature_id_2 - FK, references variation_feature table
# population_id - FK, references population
# seq_region_id_ - FK, references seq_region table
# seq_region_start_ - where the region start
# seq_region_end -  where the region ends
# r2 - value: D^2/(frq(A)*frq(B)*frq(a)*frq(b))
# d_prime - value: D/Dmax
# sample_count - value: N

create table pairwise_ld(
	variation_feature_id_1 int not null,
	variation_feature_id_2 int not null,
	population_id int not null,
	seq_region_id int not null,
	seq_region_start int not null,
	seq_region_end int not null,
	r2 float not null,
	d_prime float not null,
	sample_count int not null,
	
	key seq_region_idx(seq_region_id,seq_region_start)
);


#
# meta_coord
#
# Same table structure as in core database. Contains info about what coord
# systems features can be found in.
#
# table_name - name of the feature table
# coord_system_id - foreign key to core database coord_system table
#                   refers to coord system that features from this table can
#                   be found in
#

CREATE TABLE meta_coord (

  table_name                  VARCHAR(40) NOT NULL,
  coord_system_id             INT NOT NULL,
  max_length		      INT,

  UNIQUE(table_name, coord_system_id)

) TYPE=MyISAM;


################################################################################
#
# Table structure for table 'meta' 
#

CREATE TABLE meta (

  meta_id 		      INT not null auto_increment,
  meta_key                    varchar( 40 ) not null,
  meta_value                  varchar( 255 ) not null,

  PRIMARY KEY( meta_id ),
  KEY meta_key_index ( meta_key ),
  KEY meta_value_index ( meta_value )

);

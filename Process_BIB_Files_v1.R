# Load the libraries necessary for this procedure
library(bibliometrix)
library(openxlsx2)
library(bibtex)
library(RefManageR)


# Set the location of the working directory for facilitating the handling of the files
# In case the code below does not work run first this line
# file.choose()
# This way we reset the pointer to the Working Directory
location <- choose.dir(default = getwd(), caption = 'Select folder')

# Check if a valid directory was chosen
if (!is.na(location)) {
  setwd(location)
} else {
  stop("No valid directory selected. Please choose a valid directory.")
}


# converting them to a bib file compatible with Bibliometrix
# You must write here the name of the files you exported from WOS or SCOPUS
scopus_bib <- convert2df(file = 'scopus_10570.bib',format = 'bibtex', dbsource = 'scopus',remove.duplicates = FALSE)
wos_bib    <- convert2df(file = 'wos_merged.bib',format = 'bibtex', dbsource = 'wos',remove.duplicates = FALSE)
size_scopus <- nrow(scopus_bib)
size_wos <- nrow(wos_bib)


# Merge the files, clean the duplicates and verify its size now
db_unified <- mergeDbSources(scopus_bib,wos_bib,remove.duplicated = TRUE, verbose = TRUE)
size_unified <- nrow(db_unified)

# Remove records with no DOI number
db_unified_with_doi <- db_unified[!is.na(db_unified$DI), ]
size_with_doi <- nrow(db_unified_with_doi)

# Filter again to verify the records actually have the KEYWORDS in the TITLE, ABSTRACT
# or AUTHOR KEYWORDS as it is expected. 
#	This is the pattern I am using (“business” and “platform-based”)  OR (“digital” and “platform” and “business”)

# Build the pattern
# In case you need it define your own rexexp here
pattern <- "(business.*platform-based)|(digital.*platform)"

#Filter the TI, AB and DE
db_filtered <- db_unified_with_doi[
    grepl(pattern = pattern,x =  db_unified_with_doi$TI, ignore.case = TRUE)|
    grepl(pattern = pattern,x =  db_unified_with_doi$AB, ignore.case = TRUE)|
      grepl(pattern = pattern,x = db_unified_with_doi$DE, ignore.case = TRUE),]
size_filtered <- nrow(db_filtered)

#Filter by JOURNAL. Select only high rank sources
journals <- paste0(c('Academy of Management Annals',
              'Academy of Management Journal',
              'Academy of Management Perspectives',
              'Academy of Management Review',
              'Administrative Science Quarterly',
              'British Journal of Management',
              'Global Strategy Journal',
              'Journal of Management',
              'Journal of Management Studies',
              'Journal of Product Innovation Management',
              'Organizational Research Methods',
              'Research Policy',
              'Strategic Entrepreneurship Journal',
              'Strategic Management Journal'),collapse = '|')

db_high_ranked <- db_filtered[grepl(pattern = journals,x = db_filtered$SO, ignore.case = TRUE),]
size_high_rank <- nrow(db_high_ranked)

#Write to an XLSX compatible with Biliometrix for its processing
write_xlsx(db_high_ranked,file = 'db_full_text.xlsx')

report <-  paste("**************************************************** \n",
"RESULTS OF THE PROCESSING \n",
"**************************************************** \n")
report <- paste0(report,'\n Records loaded from Scopus database        :   ',size_scopus[1])
report <- paste0(report,'\n Records loaded from Web of Science database: + ',size_wos[1])
report <- paste0(report,'\n -----------------------------------------------------')
report <- paste0(report,'\n Total rows received -----------------------:   ',size_scopus[1] + size_wos[1])
report <- paste0(report,'\n -----------------------------------------------------')
report <- paste0(report,'\n Duplicated records deleted ----------------: - ',size_scopus[1] + size_wos[1] - size_unified[1])
report <- paste0(report,'\n -----------------------------------------------------')
report <- paste0(report,'\n Resulting unified database size -----------:   ',size_unified[1])
report <- paste0(report,'\n Deleted records without DOI ---------------: - ',size_unified[1] - size_with_doi[1])
report <- paste0(report,'\n -----------------------------------------------------')
report <- paste0(report,'\n Resulting database ------------------------:   ',size_with_doi[1])
report <- paste0(report,'\n Deleted record (Filtered by AB, TI and DE) : - ',size_with_doi[1]-size_filtered[1])
report <- paste0(report,'\n -----------------------------------------------------')
report <- paste0(report,'\n Filtered database -------------------------:   ',size_filtered[1])
report <- paste0(report,'\n Deleted from low-rank sources -------------: - ',size_filtered[1]-size_high_rank[1])
report <- paste0(report,'\n -----------------------------------------------------')
report <- paste0(report,'\n Final sample ------------------------------:   ',size_high_rank[1])
report <- paste0(report,'\n -----------------------------------------------------')
cat(report)

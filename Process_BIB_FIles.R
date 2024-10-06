# Load the libraries necessary for this procedure
library(bibliometrix)
library(openxlsx2)
library(bibtex)
library(tcltk)

# Function to open a file dialog and filter for a certain type of files
choose_bib_file <- function(type_name,type_extension) {
  
  file_path <- tclvalue(tkgetOpenFile(filetypes = paste('{{',type_name,'} {',type_extension,'}} {{All files} *}')))
  
  if (nchar(file_path) > 0) {
    return(file_path)
  } else {
    stop("No file selected. Please select a file with the .bib extension.")
  }
}


# converting them to a bib file compatible with Bibliometrix
# Locating the files exported from WOS or SCOPUS
scopus_bib <- convert2df(file = choose_bib_file(type_name = 'Scopus Bib Files', type_extension = '.bib'),format = 'bibtex', dbsource = 'scopus',remove.duplicates = FALSE)
wos_bib    <- convert2df(file = choose_bib_file(type_name = 'Web of Science Bib Files',type_extension = '.bib'),format = 'bibtex', dbsource = 'wos',remove.duplicates = FALSE)
size_scopus <- nrow(scopus_bib)
size_wos <- nrow(wos_bib)
print(getwd())

# Merge the files, clean the duplicates and verify its size now
db_unified <- mergeDbSources(scopus_bib,wos_bib,remove.duplicated = TRUE, verbose = TRUE)
size_unified <- nrow(db_unified)



# Remove records with no DOI number
db_unified_with_doi <- db_unified[!is.na(db_unified$DI), ]
size_with_doi <- nrow(db_unified_with_doi)



# Filter again to verify the records actually have the KEYWORDS in the TITLE, ABSTRACT
# or AUTHOR KEYWORDS as it is expected. 
#	This is the pattern I am using (“business” and “platform-based”)  OR (“digital” and “platform”)

# Build the pattern, in case you need it, define your own rexexp here
pattern <- "(business.*platform-based)|(digital.*platform)"

#Filter the TI, AB and DE
db_filtered <- db_unified_with_doi[
    grepl(pattern = pattern,x =  db_unified_with_doi$TI, ignore.case = TRUE)|
    grepl(pattern = pattern,x =  db_unified_with_doi$AB, ignore.case = TRUE)|
    grepl(pattern = pattern,x = db_unified_with_doi$DE, ignore.case = TRUE),]
size_filtered <- nrow(db_filtered)




#Filter by JOURNAL NAME. Select only sources ranked in the ABS 2021 Rating from this csv list
journal_df <- read.csv('abs_2021_journals.csv',header = TRUE,encoding = 'UTF-8') 

# Convert each records from the DataFrame with the name of a journal into a RegEx pattern for filtering the records by SO.
#Creating a blank copy of the db_filtered
db_abs_journals = db_filtered[FALSE,]

#Looping through the journal list to filter the db of papers against each name in the list
for (i in 1:nrow(journal_df))
{
  # Convert the journal name to a character string
  pattern <- as.character(journal_df[i, 1])
  
  # Filtering and inserting each match into the new DataFrame
  matching_rows <- db_filtered[grepl(pattern = pattern,x = db_filtered$SO, ignore.case = TRUE),]
  db_abs_journals <- rbind(db_abs_journals,matching_rows)
}
size_abs_journals <- nrow(db_abs_journals)

#Write to an XLSX compatible with Bibliometrix for its processing
write_xlsx(db_abs_journals,file = paste0(getwd(),'/quantitative_analysis_',trim(as.character(size_abs_journals)),'_records.xlsx'),overwrite = TRUE)



# Extracting only the papers ranked over 4. Following the same steps explained above. This papers are selected for the
# QUALITATIVE ANALYSIS
db_high_rank = db_abs_journals[FALSE,]  # This data frame will store the records whose journal is rated over 4
journal_df <- journal_df[grepl(pattern = '^4.*$',x = journal_df$Rating, ignore.case = TRUE),] #Update the journal list with only those whose rating is over 4 and over.
for (i in 1:nrow(journal_df))
{
  pattern <- as.character(journal_df[i,1])
  matching_rows <- db_abs_journals[grepl(pattern = pattern,x = db_abs_journals$SO, ignore.case = TRUE),]
  db_high_rank <- rbind(db_high_rank,matching_rows)
}
size_high_rank <- nrow(db_high_rank)
write_xlsx(db_high_rank,file = paste0(getwd(),'/qualitative_analysis_',trim(as.character(size_high_rank)),'_records.xlsx'),overwrite = TRUE)




#Print a summarized report on the screen for the information of the researcher.
report <-  paste("**************************************************** \n",
"RESULTS OF THE PROCESSING \n",
"**************************************************** \n")
report <- paste0(report,'\n Records loaded from Scopus database        :   ',size_scopus[1])
report <- paste0(report,'\n Records loaded from Web of Science database: + ',size_wos[1])
report <- paste0(report,'\n -----------------------------------------------------')
report <- paste0(report,'\n Total rows received -----------------------:   ',size_scopus[1] + size_wos[1])
report <- paste0(report,'\n Duplicated records deleted ----------------: - ',size_scopus[1] + size_wos[1] - size_unified[1])
report <- paste0(report,'\n -----------------------------------------------------')
report <- paste0(report,'\n Resulting unified database size -----------:   ',size_unified[1])
report <- paste0(report,'\n Deleted records without DOI ---------------: - ',size_unified[1] - size_with_doi[1])
report <- paste0(report,'\n -----------------------------------------------------')
report <- paste0(report,'\n Resulting database ------------------------:   ',size_with_doi[1])
report <- paste0(report,'\n Deleted record (Filtered by AB, TI and DE) : - ',size_with_doi[1]-size_filtered[1])
report <- paste0(report,'\n -----------------------------------------------------')
report <- paste0(report,'\n Filtered database -------------------------:   ',size_filtered[1])
report <- paste0(report,'\n Deleted not in ABS 2021 rating ------------: - ',size_filtered[1]-size_abs_journals[1])
report <- paste0(report,'\n -----------------------------------------------------')
report <- paste0(report,'\n Records from ABS 2021 rating only ---------:   ',size_abs_journals[1])
report <- paste0(report,'\n Delete records with rating below 4 --------: - ',size_abs_journals[1] - size_high_rank[1])
report <- paste0(report,'\n -----------------------------------------------------')
report <- paste0(report,'\n Records from ABS 2021 rating 4 and over ---:   ',size_high_rank[1])
report <- paste0(report,'\n -----------------------------------------------------')
report <- paste0(report,'\n FINAL SELECTION  --------------------------:   ',size_high_rank[1])
cat(report)
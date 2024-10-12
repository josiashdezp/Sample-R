# Sample-R
Samples of projects developed in R to solve tasks or assignments during my MS and PhD studies. 

#Process_BIB_FIles.R
The first sample of code is an R script I actively used during my PhD studies. It helps to process large amount of data for an integrative bibliographic reviews. With the aid of another (superb) library, Bibliometrix, the script helps to merge two .bib files from Web of Science and Scopus databases. This is necesary because these two databases use different structure and thus their field names can differ. Therefore, in order to perfom a bibliometric (quatitative) analysis (and afterwards a qualitative one) I needed to collect and transform all the data to a single file and format. That is why Bibliometrix library is occupied, to help perform the bibliometric analysis and at the same time, use its features for easing the cleaning and modeling of the dataset. 

Several steps are included according to my original needs:
----------------------------------------------------------
Converting the files to a DataFrame and merging them
Deleting duplicates
Deleting records with no DOI
Filtering the records to ensure their titles, keywords and abstracts actually contained the keywords used during the search of bibliography
Filtering the records to obtain only papers from high-rating journals according to the ABS 2021 Journal Rating (provided from a csv file)
Selecting a final sample of papers with their rating over 3 (i.e. 4 and 4*) 

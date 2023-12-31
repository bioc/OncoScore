#### OncoScore
####
#### Copyright (c) 2016, Luca De Sano, Carlo Gambacorti Passerini, 
#### Rocco Piazza, Daniele Ramazzotti, Roberta Spinelli
#### 
#### All rights reserved. This program and the accompanying materials
#### are made available under the terms of the GNU GPL v3.0
#### which accompanies this distribution.


#' perforn the query to PubMed
#' 
#' @title perform.query
#'
#' @examples
#' data(genes)
#### \donttest{perform.query(genes[1:2])}
#' 
#' @param list.of.genes The list of genes to be used in the queries to PubMed
#' @param gene.num.limit A limit to the genes to be considered in the analysis; this is done to limit the number of queries to PubMed
#' @param custom.search A custom set of keyworkds to be used when quering PubMed
#'
#' @return The frequencies of the genes in the cancer related documents and in all the documents retireved on PubMed
#' 
#' @export perform.query
#' @importFrom utils read.table
#' 
perform.query <- function( list.of.genes,
                           gene.num.limit = 100,
                           custom.search = NA) {

    if (length(list.of.genes) == 0) {
        stop("No genes found\n")
    }
    
    # perform the analysis
    cat("### Starting the queries for the selected genes.\n")
    
    # if the data are save in a file, read it
    if (all(sapply(list.of.genes, is.character)) 
        && all(file.exists(list.of.genes))) {
        cat("### Reading the list of genes from file: ", paste(list.of.genes, collapse=' '), '\n')
        list.of.genes = read.table(file = list.of.genes,
                                   header = FALSE,
                                   row.names = NULL,
                                   check.names = FALSE,
                                   stringsAsFactors = FALSE)
    }

    if (!is.vector(list.of.genes)) {
        list.of.genes = unlist(list.of.genes)
        names(list.of.genes) = NULL
    }

    # set the genes number
    list.of.genes = unique(list.of.genes)
    genes.number = length(list.of.genes)
    
    if (genes.number > gene.num.limit) {
        stop("Too many genes to query! Please reduce the list and try again.")
    }

    # perform the query for the cancer topics
    if (!is.na(custom.search)) {
        search.fields = custom.search
    } else {
        search.fields = paste("[All Fields] AND ((lymphoma[MeSH Terms] OR lymphoma[All Fields])",
            "OR (lymphoma[MeSH Terms] OR lymphoma[All Fields] OR lymphomas[All Fields])",
            "OR (neoplasms[MeSH Terms] OR neoplasms[All Fields] OR cancer[All Fields])", 
            "OR (tumour[All Fields] OR neoplasms[MeSH Terms] OR neoplasms[All Fields]",
            "OR tumor[All Fields]) OR (neoplasms[MeSH Terms] OR neoplasms[All Fields]", 
            "OR neoplasm[All Fields]) OR (neoplasms[MeSH Terms] OR neoplasms[All Fields]", 
            "OR malignancy[All Fields]) OR (leukaemia[All Fields] OR leukemia[MeSH Terms]", 
            "OR leukemia[All Fields]) OR (neoplasms[MeSH Terms] OR neoplasms[All Fields]", 
            "OR cancers[All Fields]) OR (tumours[All Fields] OR neoplasms[MeSH Terms]", 
            "OR neoplasms[All Fields] OR tumors[All Fields]) OR (neoplasms[MeSH Terms]", 
            "OR neoplasms[All Fields] OR malignancies[All Fields]) OR (leukaemias[All Fields]", 
            "OR leukemia[MeSH Terms] OR leukemia[All Fields] OR leukemias[All Fields]))")
    }
    

    cat("\n### Performing queries for cancer literature \n")
    ans = NULL

    for (gene in list.of.genes) {
        lc = get.pubmed.driver.analysis(paste0(gene, search.fields),
                                        gene = gene)
      
        if (is.na(lc)) {
            warning('Unable to retrieve information for ', gene)
        } else if (lc == -1) {
            warning(gene, ' not found on PubMed\n')
        }
        ans = rbind(ans, lc)
    }

    rownames(ans) = list.of.genes
    colnames(ans) = 'CitationsGeneInCancer'
    pubMedPanelGenes.Cancer = ans
    
    # perform the query for all the topics
    search.fields = "[All Fields]"
    
    cat("\n### Performing queries for all the literature \n")
    ans = NULL

    for (gene in list.of.genes) {
        lc = get.pubmed.driver.analysis(paste0(gene, search.fields),
                                        gene = gene)
        if (is.na(lc)) {
            warning('Unable to retrieve information for ', gene)
        } else if (lc == -1) {
            warning(gene, ' not found on PubMed\n')
        }
        ans = rbind(ans, lc)
    }
    
    rownames(ans) = list.of.genes
    colnames(ans) = 'CitationsGene'
    pubMedPanelGenes.All = ans
    
    pubMedPanelGenes = cbind(pubMedPanelGenes.All, pubMedPanelGenes.Cancer)
    return(pubMedPanelGenes)
}


#' perforn the query to PubMed for the time series analysis
#' 
#' @title perform.query.timeseries
#'
#' @examples
#' data(genes)
#' data(timepoints)
#### \donttest{perform.query.timeseries(genes[1:2], timepoints[1:2])}
#' 
#' @param list.of.genes The list of genes to be used in the queries to PubMed
#' @param list.of.datatimes The list of time points to be used in the queries to PubMed 
#' @param gene.num.limit A limit to the genes to be considered in the analysis; this is done to limit the number of queries to PubMed
#' @param timepoints.limit A limit to the time points to be considered in the analysis; this is done to limit the number of queries to PubMed
#' @param custom.search A custom set of keyworkds to be used when quering PubMed
#'
#' @return The frequencies of the genes in the cancer related documents and in all the documents retireved on PubMed at the specified time points
#' 
#' @export perform.query.timeseries
#' @importFrom utils read.table
#'
perform.query.timeseries <- function( list.of.genes,
                                      list.of.datatimes,
                                      gene.num.limit = 100,
                                      timepoints.limit = 10,
                                      custom.search = NA ) {
    
    
    if (length(list.of.genes) == 0) {
        stop("No genes found\n")
    }

    if (length(list.of.datatimes) == 0) {
        stop("No datetimes found\n")
    }

    # perform the analysis
    cat("### Starting the queries for the selected genes.\n")
    
    # if the data are save in a file, read it
    if (all(sapply(list.of.genes, is.character)) 
        && all(file.exists(list.of.genes))) {
        cat("### Reading the list of genes from file: ", paste(list.of.genes, collapse=' '), '\n')
        list.of.genes = read.table(file = list.of.genes,
                                   header = FALSE,
                                   row.names = NULL,
                                   check.names = FALSE,
                                   stringsAsFactors = FALSE)
    }

    if (!is.vector(list.of.genes)) {
        list.of.genes = unlist(list.of.genes)
        names(list.of.genes) = NULL
    }

    # set the genes number
    list.of.genes = unique(list.of.genes)
    genes.number = length(list.of.genes)
    
    if (genes.number > gene.num.limit) {
        stop("Too many genes to query! Please reduce the list and try again.")
    }


    ## Prepare and check list of datatimes

    # if the data are save in a file, read it
    if (all(sapply(list.of.datatimes, is.character)) 
        && all(file.exists(list.of.datatimes))) {
        cat("### Reading the list of datatimes from file: ", paste(list.of.datatimes, collapse=' '), '\n')
        list.of.datatimes = read.table(file = list.of.datatimes,
                                   header = FALSE,
                                   row.names = NULL,
                                   check.names = FALSE,
                                   stringsAsFactors = FALSE)
    }

    if (any(!is.na(list.of.datatimes)) && !is.vector(list.of.datatimes)) {
        list.of.datatimes = unlist(list.of.datatimes)
        names(list.of.datatimes) = NULL
    }

    if (any(!is.na(list.of.datatimes))) {
        # set the datetime number
        list.of.datatimes = unique(list.of.datatimes)
        datetimes.number = length(list.of.datatimes)
        
        if (datetimes.number > timepoints.limit) {
            stop("Too many timepoints to query! Please reduce the list and try again.")
        }
    }
  
    # repeat the query for all the time points

    pubMedPanelGenes = NULL
    for(time in list.of.datatimes) {
        cat("### Quering PubMed for timepoint", time, '\n')
    
        # perform the query for the cancer topics
        if (!is.na(custom.search)) {
            search.fields = paste0(custom.search,
                               "(0001/01/01[PDAT] : ",
                               time,
                               "[PDAT])")
        } else {
            search.fields = paste0("[All Fields] AND ((lymphoma[MeSH Terms] OR lymphoma[All Fields])",
                "OR (lymphoma[MeSH Terms] OR lymphoma[All Fields] OR lymphomas[All Fields])",
                "OR (neoplasms[MeSH Terms] OR neoplasms[All Fields] OR cancer[All Fields])",
                "OR (tumour[All Fields] OR neoplasms[MeSH Terms] OR neoplasms[All Fields]",
                "OR tumor[All Fields]) OR (neoplasms[MeSH Terms] OR neoplasms[All Fields]",
                "OR neoplasm[All Fields]) OR (neoplasms[MeSH Terms] OR neoplasms[All Fields]", 
                "OR malignancy[All Fields]) OR (leukaemia[All Fields] OR leukemia[MeSH Terms]",
                "OR leukemia[All Fields]) OR (neoplasms[MeSH Terms] OR neoplasms[All Fields]",
                "OR cancers[All Fields]) OR (tumours[All Fields] OR neoplasms[MeSH Terms]",
                "OR neoplasms[All Fields] OR tumors[All Fields]) OR (neoplasms[MeSH Terms]",
                "OR neoplasms[All Fields] OR malignancies[All Fields]) OR (leukaemias[All Fields]", 
                "OR leukemia[MeSH Terms] OR leukemia[All Fields] OR leukemias[All Fields])) AND ",
                "(0001/01/01[PDAT] : ",time, "[PDAT])")
        }
        
        cat("    ### Performing queries for cancer literature \n")
        ans = NULL
        for (gene in list.of.genes) {
            lc = get.pubmed.driver.analysis(paste0(gene, search.fields),
                                            gene = gene)
            if (lc == -1) {
                warning(gene, ' not found on PubMed\n')
            }
            ans = rbind(ans, lc)
        }
        
        rownames(ans) = list.of.genes
        colnames(ans) = 'CitationsGeneInCancer'
        pubMedPanelGenes.Cancer = ans
        
        # perform the query for all the topics
        search.fields = paste0("[All Fields]",
                               "(0001/01/01[PDAT] : ",
                               time,
                               "[PDAT])")
        
        cat("    ### Performing queries for all the literature \n")
        ans = NULL
        for(gene in list.of.genes) {
            lc = get.pubmed.driver.analysis(paste0(gene, search.fields),
                                            gene = gene)
            if (lc == -1) {
                warning(gene, ' not found on PubMed\n')
            }
            ans = rbind(ans, lc)
        }
        rownames(ans) = list.of.genes
        colnames(ans) = 'CitationsGene'
        
        pubMedPanelGenes.All = ans
        pubMedPanelGenes[[time]] = cbind(pubMedPanelGenes.All, pubMedPanelGenes.Cancer)
        
    }
    return(pubMedPanelGenes)
}


#' Perform the query to PubMed on a given chromosomic region
#' 
#' @title perform.query.from.region
#' 
#' @examples
#' chromosome = 15
#' start = 200000
#' end = 300000
#### \donttest{perform.query.from.region(chromosome, start, end)}
#' 
#' @param chromosome chromosome to be retireved
#' @param start initial position to be used
#' @param end final position to be used
#' @param gene.num.limit A limit to the genes to be considered in the analysis; this is done to limit the number of queries to PubMed
#'
#' @return The frequencies of the genes in the cancer related documents and in all the documents retireved on PubMed
#' 
#' @export perform.query.from.region
#' 
#' 
perform.query.from.region <- function( chromosome,
                                       start = NA,
                                       end = NA,
                                       gene.num.limit = 100) {

    cat("### Performing query on BioMart \n")

    genes = get.genes.from.biomart(chromosome, start, end)

    if (length(genes) > gene.num.limit) {
        cat("### Too many genes, only first", gene.num.limit, "will be used\n")
        genes = genes[1:gene.num.limit]
    } else if (length(genes) == 0) {
        stop("No genes found\n")
    }

    cat("### Performing web query on: ")
    cat(paste(genes, collapse = " "), "\n")


    query = perform.query(list.of.genes = genes,
                              gene.num.limit = gene.num.limit)

    return(query)
}

library(tidyverse)
library(glue)

library(airtabler)
dotenv::load_dot_env()
exploralatam <- airtable(
    base = "appBLpFyIMDxjmqk7",
    tables = c("reporte","organizaciones", "acciones", "compromisos")
  )

orgs0 <- exploralatam$organizaciones$select_all()
orgs0 <- mop::na_to_empty_chr(orgs0, empty = c(NA, "NA"))
reporte0 <- exploralatam$reporte$select_all()
reporte0 <- mop::na_to_empty_chr(reporte0, empty = c(NA, "NA"))
acciones0 <- exploralatam$acciones$select_all()
acciones0 <- mop::na_to_empty_chr(acciones0, empty = c(NA, "NA"))
compromisos0 <- exploralatam$compromisos$select_all()
compromisos0 <- mop::na_to_empty_chr(compromisos0, empty = c(NA, "NA"))


### ORGS


orgs <- transpose(orgs0)

# Test with one Org
set.seed(20190722)
org <- orgs[[sample(length(orgs),1)]]

org$org_type <- "NNN"

org_defaults <- list(
  date_last_modified = NULL,
  name = "_NOMBRE NO ENCONTRADO_",
  legal_name = NULL,
  description = NULL,
  org_type = "Desconocido",
  url = "No url",
  year_founded = NULL,
  projects = "No información sobre proyectos de esta organización"
)
org2 <- modifyList(org_defaults, org)

#org_inits <- initiatives0 %>% filter(id %in% org$initiatives) %>% select(uid, name) %>% transpose()
#org2$projects <- map(org_inits, ~glue_data(.,"- [{name}](/i/{uid}.html)")) %>% paste(collapse = "\n")
#org_tags <- tags0 %>% filter(id %in% org$tags) %>% filter(uid != "NA") %>% select(uid, name) %>% transpose()
#org2$tags <- map(org_tags, ~glue_data(.,"  - {uid}")) %>% paste(collapse = "\n")
#org_cities <- cities0 %>% filter(id %in% org$cities) %>% filter(name != "NA") %>% select(name) %>% transpose()
#org2$cities <- map(org_cities, ~glue_data(.,"  - {name}")) %>% paste(collapse = "\n")

org_tpl <- read_lines("scripts/org-template.md") %>% paste(collapse = "\n")

glue_data(org2, org_tpl)

### Generate files

map(orgs, function(org){
  org2 <- modifyList(org_defaults, org)
  #org_inits <- initiatives0 %>% filter(id %in% org$initiatives) %>% select(uid, name) %>% transpose()
  #org2$projects <- map(org_inits, ~glue_data(.,"- [{name}](/i/{uid}.html)")) %>% paste(collapse = "\n")
  # org_tags <- tags0 %>% filter(id %in% org$tags) %>% filter(uid != "NA") %>% select(uid, name) %>% transpose()
  # org2$tags <- map(org_tags, ~glue_data(.,"  - {uid}")) %>% paste(collapse = "\n")
  # org_cities <- cities0 %>% filter(id %in% org$cities) %>% filter(name != "NA") %>% select(name) %>% transpose()
  # org2$cities <- map(org_cities, ~glue_data(.,"  - {name}")) %>% paste(collapse = "\n")
  md <- glue_data(org2, org_tpl)
  write_lines(md, paste0("content/organizaciones/", org$uid, ".md"))
})


library(tidyverse)
library(glue)

library(airtabler)
dotenv::load_dot_env()
ongxt <- airtable(
    base = "appBLpFyIMDxjmqk7",
    tables = c("reporte","organizaciones", "acciones", "compromisos", "puntaje")
  )

orgs0 <- ongxt$organizaciones$select_all()
orgs0 <- mop::na_to_empty_chr(orgs0, empty = c(NA, "NA"))
reporte0 <- ongxt$reporte$select_all()
#reporte0 <- mop::na_to_empty_chr(reporte0, empty = c(NA, "NA"))
acciones0 <- ongxt$acciones$select_all()
acciones0 <- mop::na_to_empty_chr(acciones0, empty = c(NA, "NA"))
compromisos0 <- ongxt$compromisos$select_all()
compromisos0 <- mop::na_to_empty_chr(compromisos0, empty = c(NA, "NA"))
puntaje0 <- ongxt$puntaje$select_all()
puntaje0 <- mop::na_to_empty_chr(puntaje0, empty = c(NA, "NA"))

reportes <- reporte0 %>%
  mutate(organizacion = unlist(organizacion),
         compromiso = unlist(compromiso),
         accion = unlist(accion))
reportes <- left_join(reportes, orgs0 %>% select(id, nombre, uid), by = c("organizacion" = "id"))
reportes <- left_join(reportes,
                      compromisos0 %>% select(id, nombre, titulo, descripcion),
                      by = c("compromiso" = "id"))
reportes <- left_join(reportes,
                      acciones0 %>% select(id, descripcion, acciones, grupo, nombre),
                      by = c("accion" = "id"))

reportes1 <- reportes %>%
  select(organizacion_uid = uid,
         organizacion_nombre = nombre.y,
         puntaje, year, respuesta_abierta,
         compromiso_numero = nombre.x.x,
         compromiso_nombre = titulo,
         compromiso_descripcion = descripcion.x,
         accion = acciones,
         acciones_descripcion = descripcion.y,
         accion_grupo = grupo
         ) %>%
  arrange(organizacion_uid,compromiso_numero, accion_grupo, accion)


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

rep_org <- reportes1 %>% filter(organizacion_uid == org2$uid)
rep_quant <- rep_org %>% filter(!is.na(puntaje)) %>%
  group_by(compromiso_numero, compromiso_nombre, compromiso_descripcion) %>%
  summarise(puntaje = sum(puntaje)) %>%
  separate(compromiso_numero, c("compromiso", "numero")) %>%
  mutate(numero = as.numeric(numero)) %>%
  arrange(numero) %>%
  unite(compromiso, numero)
names(rep_quant) <- c("Compromiso", "Número", "Descripción", "Puntaje")
rep_quant_org <- knitr::kable(rep_quant)

org2$reporte <- paste(rep_quant_org, collapse = "\n")
org_tpl <- read_lines("scripts/org-template.md") %>% paste(collapse = "\n")

glue_data(org2, org_tpl)

### Generate files

map(orgs, function(org){
  org2 <- modifyList(org_defaults, org)
  rep_org <- reportes1 %>% filter(organizacion_uid == org2$uid)
  rep_quant <- rep_org %>% filter(!is.na(puntaje)) %>%
    group_by(compromiso_numero, compromiso_nombre, compromiso_descripcion) %>%
    summarise(puntaje = sum(puntaje)) %>%
    separate(compromiso_numero, c("compromiso", "numero")) %>%
    mutate(numero = as.numeric(numero)) %>%
    arrange(numero) %>%
    unite(compromiso, numero)
  names(rep_quant) <- c("Compromiso", "Número", "Descripción", "Puntaje")
  rep_quant_org <- knitr::kable(rep_quant)
  org2$reporte <- paste(rep_quant_org, collapse = "\n")
  org_tpl <- read_lines("scripts/org-template.md") %>% paste(collapse = "\n")
  md <- glue_data(org2, org_tpl)
  write_lines(md, paste0("content/organizaciones/", org$uid, ".md"))
})


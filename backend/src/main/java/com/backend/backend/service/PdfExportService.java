package com.backend.backend.service;

import com.backend.backend.dao.entities.StatutFuite;
import com.backend.backend.dto.rapport.FuiteDetailDto;
import com.backend.backend.dto.rapport.FuiteResumeDto;
import com.backend.backend.dto.rapport.RapportResponseDto;
import com.itextpdf.kernel.colors.Color;
import com.itextpdf.kernel.colors.DeviceRgb;
import com.itextpdf.kernel.font.PdfFont;
import com.itextpdf.kernel.font.PdfFontFactory;
import com.itextpdf.kernel.pdf.PdfDocument;
import com.itextpdf.kernel.pdf.PdfWriter;
import com.itextpdf.kernel.pdf.xobject.PdfFormXObject;
import com.itextpdf.layout.Canvas;
import com.itextpdf.layout.Document;
import com.itextpdf.layout.borders.Border;
import com.itextpdf.layout.properties.BorderRadius;
import com.itextpdf.layout.borders.SolidBorder;
import com.itextpdf.layout.element.*;
import com.itextpdf.layout.properties.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import javax.imageio.ImageIO;
import java.awt.*;
import java.awt.geom.Arc2D;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

@Service
@RequiredArgsConstructor
public class PdfExportService {

    private final RapportService rapportService;

    // ── Palette OCP (identique au UI Flutter) ──
    private static final Color VERT_FONCE   = new DeviceRgb(0, 89, 65);
    private static final Color VERT_MOYEN   = new DeviceRgb(0, 120, 85);
    private static final Color VERT_SUCCES  = new DeviceRgb(40, 167, 69);
    private static final Color ROUGE        = new DeviceRgb(211, 47, 47);
    private static final Color ORANGE       = new DeviceRgb(245, 124, 0);
    private static final Color BLEU         = new DeviceRgb(21, 101, 192);
    private static final Color GRIS_FONCE   = new DeviceRgb(60, 60, 60);
    private static final Color GRIS_MOYEN   = new DeviceRgb(117, 117, 117);
    private static final Color GRIS_CLAIR   = new DeviceRgb(245, 245, 245);
    private static final Color BLANC        = new DeviceRgb(255, 255, 255);
    private static final Color VERT_FOND    = new DeviceRgb(232, 245, 233);
    private static final Color ROUGE_FOND   = new DeviceRgb(255, 235, 238);
    private static final Color ORANGE_FOND  = new DeviceRgb(255, 243, 224);

    private static final Map<String, String> STATUT_LABELS = Map.of(
            "A_REPARER", "À réparer",
            "EN_COURS", "En cours",
            "REPAREE", "Réparée",
            "ANNULEE", "Annulée"
    );
    private static final Map<String, Color> STATUT_COULEURS = Map.of(
            "A_REPARER", ROUGE,
            "EN_COURS", ORANGE,
            "REPAREE", VERT_SUCCES,
            "ANNULEE", GRIS_MOYEN
    );

    /**
     * Génère le PDF complet (toutes les métriques) — préservation de la signature existante.
     */
    public byte[] genererPdf(Long projetId, String periode) {
        return genererPdf(projetId, periode, null);
    }

    /**
     * Génère le PDF avec les métriques sélectionnées uniquement.
     * @param metrics Ensemble d'IDs de métriques à inclure (null ou vide = toutes).
     */
    public byte[] genererPdf(Long projetId, String periode, Set<String> metrics) {
        RapportResponseDto rapport = rapportService.genererRapportByProjet(projetId, periode);

        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        PdfDocument pdf = new PdfDocument(new PdfWriter(baos));
        Document doc = new Document(pdf);
        doc.setMargins(25, 25, 25, 25);

        PdfFont boldFont = getFont(true);
        PdfFont regularFont = getFont(false);

        // Si metrics est null ou vide, tout afficher
        boolean all = (metrics == null || metrics.isEmpty());

        // ═══════════════════════════════════════════════
        // HEADER (toujours affiché)
        // ═══════════════════════════════════════════════
        Table headerTable = new Table(2);
        headerTable.setWidth(UnitValue.createPercentValue(100));

        Cell titleCell = new Cell().setBorder(Border.NO_BORDER);
        titleCell.add(new Paragraph("Rapport de Surveillance")
                .setFont(boldFont).setFontSize(20).setFontColor(VERT_FONCE));
        titleCell.add(new Paragraph("Fuites de vapeur — OCP")
                .setFont(regularFont).setFontSize(11).setFontColor(GRIS_MOYEN));
        headerTable.addCell(titleCell);

        Cell periodCell = new Cell().setBorder(Border.NO_BORDER).setTextAlignment(TextAlignment.RIGHT);
        periodCell.add(new Paragraph(rapport.getPeriodeLibelle())
                .setFont(boldFont).setFontSize(13).setFontColor(VERT_FONCE));
        periodCell.add(new Paragraph(rapport.getDateDebut() + " → " + rapport.getDateFin())
                .setFont(regularFont).setFontSize(9).setFontColor(GRIS_MOYEN));
        headerTable.addCell(periodCell);

        doc.add(headerTable);
        doc.add(new Paragraph().setHeight(2).setBackgroundColor(VERT_FONCE).setMarginBottom(16));

        // ═══════════════════════════════════════════════
        // 1. TOP PRIORITY — Pertes vs Économies (KPI cards)
        // ═══════════════════════════════════════════════
        if (all || metrics.contains("top_priority")) {
            Table kpiTable = new Table(3);
            kpiTable.setWidth(UnitValue.createPercentValue(100));
            kpiTable.setMarginBottom(16);

            kpiTable.addCell(creerKpiCell("Total fuites", String.valueOf(rapport.getTotalFuites()),
                    "fuites", GRIS_FONCE, regularFont, boldFont));
            kpiTable.addCell(creerKpiCell("Coût fuites actives",
                    formatMonnaie(rapport.getCoutFuitesActives()),
                    "MAD / an", ROUGE, regularFont, boldFont));
            kpiTable.addCell(creerKpiCell("Économies réalisées",
                    formatMonnaie(rapport.getEconomiesRealisees()),
                    "MAD / an", VERT_SUCCES, regularFont, boldFont));

            doc.add(kpiTable);
        }

        // ═══════════════════════════════════════════════
        // 2. NOMBRE DE FUITES PAR CAMPAGNE (avec barres + détails)
        // ═══════════════════════════════════════════════
        if ((all || metrics.contains("nb_campagnes")) && rapport.getFuitesParCampagne() != null && !rapport.getFuitesParCampagne().isEmpty()) {
            doc.add(titreSection("Nombre de fuites par campagne", boldFont));
            int totalFuitesCamp = rapport.getFuitesParCampagne().values().stream().mapToInt(i -> i).sum();

            Table barTable = new Table(new float[]{3, 1});
            barTable.setWidth(UnitValue.createPercentValue(100));
            barTable.setMarginBottom(8);

            for (Map.Entry<String, Integer> e : rapport.getFuitesParCampagne().entrySet()) {
                double ratio = totalFuitesCamp > 0 ? (double) e.getValue() / totalFuitesCamp : 0;
                barTable.addCell(creerCellule(e.getKey(), regularFont));
                barTable.addCell(creerCelluleAvecBarre(e.getValue() + " fuite(s)", ratio, VERT_MOYEN, boldFont));
            }
            doc.add(barTable);

            // ── Détail des fuites par campagne ──
            if (rapport.getFuitesDetailleesParCampagne() != null
                    && !rapport.getFuitesDetailleesParCampagne().isEmpty()) {
                doc.add(new Paragraph("Détail des fuites par campagne :")
                        .setFont(boldFont).setFontSize(10).setFontColor(GRIS_FONCE)
                        .setMarginBottom(4));

                for (Map.Entry<String, Integer> e : rapport.getFuitesParCampagne().entrySet()) {
                    String campagneNom = e.getKey();
                    List<FuiteDetailDto> details = rapport.getFuitesDetailleesParCampagne()
                            .getOrDefault(campagneNom, List.of());

                    if (details.isEmpty()) continue;

                    doc.add(new Paragraph(campagneNom)
                            .setFont(boldFont).setFontSize(9).setFontColor(VERT_FONCE)
                            .setMarginTop(4).setMarginBottom(2));

                    // Cacher les lignes : Tag | Localisation | Date
                    Table detailTable = new Table(new float[]{1.2f, 2.5f, 1.3f});
                    detailTable.setWidth(UnitValue.createPercentValue(100));
                    detailTable.setMarginBottom(6);

                    // Header row
                    detailTable.addCell(creerDetailHeaderCell("Tag", boldFont));
                    detailTable.addCell(creerDetailHeaderCell("Localisation", boldFont));
                    detailTable.addCell(creerDetailHeaderCell("Date / Heure", boldFont));

                    for (FuiteDetailDto f : details) {
                        detailTable.addCell(creerDetailCell(
                                f.getNumeroTag() != null ? f.getNumeroTag() : "—", regularFont));
                        detailTable.addCell(creerDetailCell(
                                f.getLocalisation() != null && !f.getLocalisation().isEmpty()
                                        ? f.getLocalisation() : "—", regularFont));
                        detailTable.addCell(creerDetailCell(
                                f.getDateDetection() != null && !f.getDateDetection().isEmpty()
                                        ? f.getDateDetection() : "—", regularFont));
                    }
                    doc.add(detailTable);
                }
            }
        }

        // ═══════════════════════════════════════════════
        // 3. PERTES VS ÉCONOMIES PAR CAMPAGNE (barre 100% rouge/vert)
        // ═══════════════════════════════════════════════
        if ((all || metrics.contains("pertes_campagnes")) && rapport.getFuitesParCampagne() != null && !rapport.getFuitesParCampagne().isEmpty()) {
            doc.add(titreSection("Pertes vs Économies par campagne", boldFont));

            for (String nom : rapport.getFuitesParCampagne().keySet()) {
                double pertes = rapport.getPertesParCampagne() != null
                        ? rapport.getPertesParCampagne().getOrDefault(nom, 0.0) : 0.0;
                double economies = rapport.getEconomiesParCampagne() != null
                        ? rapport.getEconomiesParCampagne().getOrDefault(nom, 0.0) : 0.0;
                double total = pertes + economies;
                double ratioPertes = total > 0 ? pertes / total : 0;
                double ratioEco = total > 0 ? economies / total : 0;

                Paragraph nomCamp = new Paragraph(nom)
                        .setFont(boldFont).setFontSize(10).setFontColor(GRIS_FONCE)
                        .setMarginTop(4).setMarginBottom(2);
                doc.add(nomCamp);

                // Barre 100% : une seule ligne avec deux cellules proportionnelles
                Table bar100 = new Table(new float[]{1});
                bar100.setWidth(UnitValue.createPercentValue(100));
                bar100.setMarginBottom(2);

                Cell barContainer = new Cell().setBorder(Border.NO_BORDER)
                        .setPadding(0).setHeight(22);

                // On crée une table interne avec 2 colonnes proportionnelles
                Table innerBar = new Table(new float[]{
                        (float) Math.max(ratioPertes, 0.01),
                        (float) Math.max(ratioEco, 0.01)
                });
                innerBar.setWidth(UnitValue.createPercentValue(100));
                innerBar.setBorderRadius(new BorderRadius(5));

                Cell pertesCell = new Cell().setBorder(Border.NO_BORDER)
                        .setBackgroundColor(ROUGE)
                        .setTextAlignment(TextAlignment.CENTER)
                        .setVerticalAlignment(VerticalAlignment.MIDDLE)
                        .setHeight(20);
                pertesCell.add(new Paragraph("Pertes " + formatMonnaie(pertes))
                        .setFont(boldFont).setFontSize(7).setFontColor(BLANC));
                innerBar.addCell(pertesCell);

                Cell ecoCell = new Cell().setBorder(Border.NO_BORDER)
                        .setBackgroundColor(VERT_SUCCES)
                        .setTextAlignment(TextAlignment.CENTER)
                        .setVerticalAlignment(VerticalAlignment.MIDDLE)
                        .setHeight(20);
                ecoCell.add(new Paragraph("Économies " + formatMonnaie(economies))
                        .setFont(boldFont).setFontSize(7).setFontColor(BLANC));
                innerBar.addCell(ecoCell);

                barContainer.add(innerBar);
                bar100.addCell(barContainer);
                doc.add(bar100);

                // Légende sous la barre
                Table legendTable = new Table(new float[]{1, 1});
                legendTable.setWidth(UnitValue.createPercentValue(100));
                legendTable.setMarginBottom(6);

                Paragraph pertesLegende = new Paragraph()
                        .add(creerCercle(ROUGE))
                        .add(new Text("  Pertes : " + formatMonnaie(pertes))
                                .setFont(regularFont).setFontSize(8).setFontColor(ROUGE));
                legendTable.addCell(creerCelluleBrute(pertesLegende, BLANC));

                Paragraph ecoLegende = new Paragraph()
                        .add(creerCercle(VERT_SUCCES))
                        .add(new Text("  Économies : " + formatMonnaie(economies))
                                .setFont(regularFont).setFontSize(8).setFontColor(VERT_SUCCES));
                legendTable.addCell(creerCelluleBrute(ecoLegende, BLANC));

                doc.add(legendTable);
            }
        }

        // ═══════════════════════════════════════════════
        // 4. COÛT PAR STATUT (avec barres colorées)
        // ═══════════════════════════════════════════════
        if ((all || metrics.contains("cout_statut")) && rapport.getCoutParStatut() != null && !rapport.getCoutParStatut().isEmpty()) {
            doc.add(titreSection("Coût total par statut", boldFont));
            double totalCout = rapport.getCoutParStatut().values().stream().mapToDouble(d -> d).sum();

            Table statutTable = new Table(new float[]{1, 2.5f, 1.5f});
            statutTable.setWidth(UnitValue.createPercentValue(100));
            statutTable.setMarginBottom(14);

            for (Map.Entry<String, Double> e : rapport.getCoutParStatut().entrySet()) {
                String label = STATUT_LABELS.getOrDefault(e.getKey(), e.getKey());
                Color couleur = STATUT_COULEURS.getOrDefault(e.getKey(), GRIS_MOYEN);
                double ratio = totalCout > 0 ? e.getValue() / totalCout : 0;

                // Cercle coloré + label
                Paragraph labelP = new Paragraph();
                labelP.add(creerCercle(couleur));
                labelP.add(new Text("  " + label).setFont(regularFont).setFontSize(10).setFontColor(GRIS_FONCE));
                statutTable.addCell(creerCelluleBrute(labelP, GRIS_CLAIR));

                // Barre de progression
                statutTable.addCell(creerCelluleBarre(ratio, couleur));

                // Valeur
                statutTable.addCell(creerCelluleValeur(formatMonnaie(e.getValue()), boldFont, GRIS_FONCE));
            }
            doc.add(statutTable);
        }

        // ═══════════════════════════════════════════════
        // 5. TAUX DE RÉPARATION (jauge + liste)
        // ═══════════════════════════════════════════════
        if ((all || metrics.contains("taux_reparation")) && rapport.getTauxReparationGlobal() != null) {
            doc.add(titreSection("Taux de réparation", boldFont));

            double taux = rapport.getTauxReparationGlobal();
            Color tauxCouleur = taux >= 50 ? VERT_SUCCES : ORANGE;

            // Ligne globale : jauge circulaire simplifiée + texte
            Table tauxRow = new Table(new float[]{1, 2});
            tauxRow.setWidth(UnitValue.createPercentValue(70));
            tauxRow.setMarginBottom(10);

            // Jauge ronde (on dessine un cercle avec le % dedans)
            Cell gaugeCell = new Cell().setBorder(Border.NO_BORDER)
                    .setTextAlignment(TextAlignment.CENTER)
                    .setPadding(8);
            // On utilise juste le texte en grand avec un fond
            Paragraph gaugeP = new Paragraph(String.format("%.0f%%", taux))
                    .setFont(boldFont).setFontSize(22).setFontColor(tauxCouleur)
                    .setTextAlignment(TextAlignment.CENTER)
                    .setBackgroundColor(GRIS_CLAIR)
                    .setPadding(12);
            gaugeCell.add(gaugeP);
            tauxRow.addCell(gaugeCell);

            Cell infoCell = new Cell().setBorder(Border.NO_BORDER)
                    .setVerticalAlignment(VerticalAlignment.MIDDLE);
            infoCell.add(new Paragraph("Global")
                    .setFont(boldFont).setFontSize(12).setFontColor(GRIS_FONCE));
            int totalFuites = rapport.getTotalFuites();
            int fuitesReparees = (int) Math.round(totalFuites * rapport.getTauxReparationGlobal() / 100.0);
            infoCell.add(new Paragraph(String.format("%d / %d fuites réparées", fuitesReparees, totalFuites))
                    .setFont(regularFont).setFontSize(10).setFontColor(GRIS_MOYEN));
            tauxRow.addCell(infoCell);

            doc.add(tauxRow);

            // Taux par campagne (badges)
            if (rapport.getTauxReparationParCampagne() != null
                    && !rapport.getTauxReparationParCampagne().isEmpty()) {
                doc.add(new Paragraph("Par campagne :")
                        .setFont(boldFont).setFontSize(10).setFontColor(GRIS_FONCE)
                        .setMarginBottom(4));

                Table tauxCampTable = new Table(2);
                tauxCampTable.setWidth(UnitValue.createPercentValue(80));
                tauxCampTable.setMarginBottom(14);

                for (Map.Entry<String, Double> e : rapport.getTauxReparationParCampagne().entrySet()) {
                    double val = e.getValue();
                    Color badgeCouleur = val >= 50 ? VERT_SUCCES : ORANGE;
                    Color badgeFond = val >= 50 ? VERT_FOND : ORANGE_FOND;

                    tauxCampTable.addCell(creerCellule(e.getKey(), regularFont));

                    Cell badgeCell = new Cell().setBorder(Border.NO_BORDER)
                            .setTextAlignment(TextAlignment.RIGHT)
                            .setPadding(4);
                    Paragraph badgeP = new Paragraph(String.format("%.0f%%", val))
                            .setFont(boldFont).setFontSize(10).setFontColor(badgeCouleur)
                            .setBackgroundColor(badgeFond)
                            .setTextAlignment(TextAlignment.CENTER);
                    badgeP.setPaddingLeft(6).setPaddingRight(6)
                           .setPaddingTop(3).setPaddingBottom(3);
                    badgeCell.add(badgeP);
                    tauxCampTable.addCell(badgeCell);
                }
                doc.add(tauxCampTable);
            }
        }

        // ═══════════════════════════════════════════════
        // 6. TOP 5 FUITES ACTIVES
        // ═══════════════════════════════════════════════
        if ((all || metrics.contains("top5_actives")) && rapport.getTop5Actives() != null && !rapport.getTop5Actives().isEmpty()) {
            doc.add(titreSection("Top 5 fuites actives les plus coûteuses", boldFont));
            doc.add(creerTableTop5(rapport.getTop5Actives(), regularFont, boldFont, ROUGE));
        }

        // ═══════════════════════════════════════════════
        // 7. TOP 5 FUITES RÉPARÉES
        // ═══════════════════════════════════════════════
        if ((all || metrics.contains("top5_reparees")) && rapport.getTop5Reparees() != null && !rapport.getTop5Reparees().isEmpty()) {
            doc.add(titreSection("Top 5 fuites réparées — économies réalisées", boldFont));
            doc.add(creerTableTop5(rapport.getTop5Reparees(), regularFont, boldFont, VERT_SUCCES));
        }

        // ═══════════════════════════════════════════════
        // 8. DIAGRAMMES CIRCULAIRES (Pie charts avec légende)
        // ═══════════════════════════════════════════════
        if (all || metrics.contains("diagrammes")) {
            doc.add(titreSection("Répartition par campagne", boldFont));

            // 8a. Nombre de fuites (diagramme circulaire)
            if (rapport.getRepartitionNbrCampagnes() != null
                    && !rapport.getRepartitionNbrCampagnes().isEmpty()) {
                doc.add(sousTitreSection("Nombre de fuites", BLEU, boldFont));
                doc.add(creerPieChartImage(rapport.getRepartitionNbrCampagnes(), regularFont, boldFont));
            }

            // 8b. Pertes estimées (diagramme circulaire)
            if (rapport.getRepartitionPertesCampagnes() != null
                    && !rapport.getRepartitionPertesCampagnes().isEmpty()) {
                doc.add(sousTitreSection("Pertes estimées (MAD)", ROUGE, boldFont));
                Map<String, Integer> pertesInt = new LinkedHashMap<>();
                for (Map.Entry<String, Double> e : rapport.getRepartitionPertesCampagnes().entrySet()) {
                    pertesInt.put(e.getKey(), e.getValue().intValue());
                }
                doc.add(creerPieChartImage(pertesInt, regularFont, boldFont));
            }

            // 8c. Économies (diagramme circulaire)
            if (rapport.getRepartitionEconomiesCampagnes() != null
                    && !rapport.getRepartitionEconomiesCampagnes().isEmpty()) {
                doc.add(sousTitreSection("Économies (MAD)", VERT_SUCCES, boldFont));
                Map<String, Integer> ecoInt = new LinkedHashMap<>();
                for (Map.Entry<String, Double> e : rapport.getRepartitionEconomiesCampagnes().entrySet()) {
                    ecoInt.put(e.getKey(), e.getValue().intValue());
                }
                doc.add(creerPieChartImage(ecoInt, regularFont, boldFont));
            }
        }

        // ═══════════════════════════════════════════════
        // FOOTER
        // ═══════════════════════════════════════════════
        doc.add(new Paragraph().setHeight(10));
        doc.add(new Paragraph("Rapport généré automatiquement — OCP Leaks Survey")
                .setFont(regularFont).setFontSize(8).setFontColor(GRIS_MOYEN)
                .setTextAlignment(TextAlignment.CENTER));

        doc.close();
        return baos.toByteArray();
    }

    // ═══════════════════════════════════════════════════
    //  HELPERS DE SECTIONS
    // ═══════════════════════════════════════════════════

    private Paragraph titreSection(String texte, PdfFont bold) {
        return new Paragraph(texte)
                .setFont(bold).setFontSize(13).setFontColor(VERT_FONCE)
                .setMarginTop(12).setMarginBottom(6);
    }

    private Paragraph sousTitreSection(String texte, Color couleur, PdfFont bold) {
        return new Paragraph(texte)
                .setFont(bold).setFontSize(10).setFontColor(couleur)
                .setMarginTop(6).setMarginBottom(4);
    }

    // ── Mini-barre colorée pour Pertes vs Économies ──
    private Cell creerMiniBarre(String texte, double ratio, Color couleur, PdfFont font) {
        Cell cell = new Cell().setBorder(Border.NO_BORDER).setPadding(2);
        Paragraph p = new Paragraph(texte)
                .setFont(font).setFontSize(9).setFontColor(couleur)
                .setMarginBottom(2);
        cell.add(p);

        // Barre colorée
        Table inner = new Table(new float[]{1});
        inner.setWidth(UnitValue.createPercentValue(100));
        Cell barCell = new Cell().setBorder(Border.NO_BORDER)
                .setBackgroundColor(GRIS_CLAIR)
                .setPadding(0).setHeight(8);
        cell.add(inner);
        return cell;
    }

    // ── Cellule avec cercle coloré (pour statut) ──
    private Text creerCercle(Color couleur) {
        // On utilise un caractère "●" comme cercle
        return new Text("●").setFontColor(couleur).setFontSize(10);
    }

    // ── Cellule avec barre de progression proportionnelle ──
    private Cell creerCelluleBarre(double ratio, Color couleur) {
        Cell cell = new Cell().setPadding(4)
                .setBorder(new SolidBorder(GRIS_CLAIR, 0.5f))
                .setVerticalAlignment(VerticalAlignment.MIDDLE);
        // Barre proportionnelle : deux colonnes (ratio / reste)
        int pct = (int) Math.round(ratio * 100);
        float colPct = Math.max(pct, 1);
        float colRest = Math.max(100 - pct, 1);
        Table barTable = new Table(new float[]{colPct, colRest});
        barTable.setWidth(UnitValue.createPercentValue(100));
        barTable.setBorderRadius(new BorderRadius(4));

        Cell barFill = new Cell().setBorder(Border.NO_BORDER)
                .setBackgroundColor(couleur)
                .setHeight(8);
        barTable.addCell(barFill);

        Cell barEmpty = new Cell().setBorder(Border.NO_BORDER)
                .setBackgroundColor(GRIS_CLAIR)
                .setHeight(8);
        barTable.addCell(barEmpty);

        cell.add(barTable);
        return cell;
    }

    // ── Cellule avec valeur + barre proportionnelle (pour fuites par campagne) ──
    private Cell creerCelluleAvecBarre(String texte, double ratio, Color couleur, PdfFont bold) {
        Cell cell = new Cell().setPadding(4)
                .setBorder(new SolidBorder(GRIS_CLAIR, 0.5f));
        // Texte à droite
        Paragraph p = new Paragraph(texte)
                .setFont(bold).setFontSize(9).setFontColor(GRIS_FONCE)
                .setTextAlignment(TextAlignment.RIGHT)
                .setMarginBottom(2);
        cell.add(p);

        // Barre proportionnelle : deux colonnes (ratio / reste)
        int pct = (int) Math.round(ratio * 100);
        float colPct = Math.max(pct, 1);
        float colRest = Math.max(100 - pct, 1);
        Table barTable = new Table(new float[]{colPct, colRest});
        barTable.setWidth(UnitValue.createPercentValue(100));
        barTable.setBorderRadius(new BorderRadius(4));

        Cell barFill = new Cell().setBorder(Border.NO_BORDER)
                .setBackgroundColor(couleur)
                .setHeight(5);
        barTable.addCell(barFill);

        Cell barEmpty = new Cell().setBorder(Border.NO_BORDER)
                .setBackgroundColor(GRIS_CLAIR)
                .setHeight(5);
        barTable.addCell(barEmpty);

        cell.add(barTable);
        return cell;
    }

    private Cell creerCelluleBrute(Paragraph contenu, Color fond) {
        return new Cell().setPadding(4)
                .setBorder(new SolidBorder(GRIS_CLAIR, 0.5f))
                .setBackgroundColor(fond)
                .add(contenu);
    }

    // ── Header cell for detail tables ──
    private Cell creerDetailHeaderCell(String texte, PdfFont bold) {
        return new Cell().setBackgroundColor(VERT_FONCE)
                .setPadding(3)
                .add(new Paragraph(texte)
                        .setFont(bold).setFontSize(7).setFontColor(BLANC)
                        .setTextAlignment(TextAlignment.CENTER));
    }

    // ── Data cell for detail tables ──
    private Cell creerDetailCell(String texte, PdfFont font) {
        return new Cell().setPadding(2)
                .setBorder(new SolidBorder(GRIS_CLAIR, 0.3f))
                .add(new Paragraph(texte).setFont(font).setFontSize(7).setFontColor(GRIS_FONCE));
    }

    // ── Génération d'un diagramme circulaire Avec légende intégrée en AWT ──
    private Table creerPieChartImage(Map<String, Integer> data,
                                     PdfFont regular, PdfFont bold) {
        int total = data.values().stream().mapToInt(i -> i).sum();
        if (total == 0) return new Table(0);

        // Palette de couleurs AWT
        java.awt.Color[] palette = {
            new java.awt.Color(21, 101, 192),   // BLEU
            new java.awt.Color(0, 89, 65),       // VERT_FONCE
            new java.awt.Color(245, 124, 0),     // ORANGE
            new java.awt.Color(211, 47, 47),     // ROUGE
            new java.awt.Color(117, 117, 117),   // GRIS_MOYEN
            new java.awt.Color(0, 120, 85),      // VERT_MOYEN
            new java.awt.Color(40, 167, 69),     // VERT_SUCCES
        };

        // Trier par valeur décroissante
        List<Map.Entry<String, Integer>> entries = data.entrySet().stream()
                .sorted(Map.Entry.<String, Integer>comparingByValue().reversed())
                .toList();

        // Dimensions
        int pieSize = 140;
        int legendWidth = 200;
        int rowH = 18;
        int padding = 10;
        int imgW = pieSize + legendWidth + padding * 2;
        int imgH = Math.max(pieSize + padding * 2, entries.size() * rowH + padding * 2);

        BufferedImage img = new BufferedImage(imgW, imgH, BufferedImage.TYPE_INT_ARGB);
        Graphics2D g2d = img.createGraphics();
        g2d.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
        g2d.setFont(new java.awt.Font("SansSerif", java.awt.Font.PLAIN, 11));

        // ── Dessiner le camembert ──
        int startAngle = 90;
        int cx = pieSize / 2 + padding;
        int cy = imgH / 2;
        int r = pieSize / 2 - 5;

        for (int i = 0; i < entries.size(); i++) {
            int val = entries.get(i).getValue();
            int arcAngle = (int) Math.round(360.0 * val / total);
            if (arcAngle == 0 && val > 0) arcAngle = 1;

            g2d.setColor(palette[i % palette.length]);
            g2d.fillArc(cx - r, cy - r, r * 2, r * 2, startAngle, -arcAngle);
            g2d.setColor(java.awt.Color.WHITE);
            g2d.setStroke(new java.awt.BasicStroke(1));
            g2d.drawArc(cx - r, cy - r, r * 2, r * 2, startAngle, -arcAngle);

            startAngle -= arcAngle;
        }

        // Bord extérieur
        g2d.setColor(java.awt.Color.LIGHT_GRAY);
        g2d.setStroke(new java.awt.BasicStroke(1));
        g2d.drawOval(cx - r, cy - r, r * 2, r * 2);

        // ── Dessiner la légende avec cercles colorés ──
        int legendX = pieSize + padding + 10;
        int legendY = padding + 12;

        for (int i = 0; i < entries.size(); i++) {
            Map.Entry<String, Integer> e = entries.get(i);
            double pct = (double) e.getValue() / total * 100;
            int y = legendY + i * rowH;

            // Cercle coloré (rempli)
            java.awt.Color awtC = palette[i % palette.length];
            g2d.setColor(awtC);
            g2d.fillOval(legendX, y - 6, 10, 10);
            g2d.setColor(java.awt.Color.DARK_GRAY);
            g2d.drawOval(legendX, y - 6, 10, 10);

            // Texte : nom + valeur + %
            g2d.setColor(java.awt.Color.DARK_GRAY);
            String legendText = e.getKey() + " : " + e.getValue() + " (" + String.format("%.0f", pct) + "%)";
            g2d.drawString(legendText, legendX + 16, y + 3);
        }

        g2d.dispose();

        // Convertir en bytes PNG
        byte[] imageBytes;
        try {
            ByteArrayOutputStream baosImg = new ByteArrayOutputStream();
            ImageIO.write(img, "png", baosImg);
            imageBytes = baosImg.toByteArray();
        } catch (Exception e) {
            return new Table(0);
        }

        com.itextpdf.io.image.ImageData imgData = com.itextpdf.io.image.ImageDataFactory.create(imageBytes);
        com.itextpdf.layout.element.Image pdfImg = new com.itextpdf.layout.element.Image(imgData);
        pdfImg.scaleToFit(imgW, imgH);

        // Cellule unique contenant l'image (camembert + légende intégrée)
        Cell imgCell = new Cell().setBorder(Border.NO_BORDER)
                .setTextAlignment(TextAlignment.CENTER)
                .setPadding(4);
        imgCell.add(pdfImg);

        Table wrapper = new Table(1);
        wrapper.setWidth(UnitValue.createPercentValue(100));
        wrapper.setMarginBottom(12);
        wrapper.addCell(imgCell);
        return wrapper;
    }

    // ═══════════════════════════════════════════════════
    //  HELPERS EXISTANTS AMÉLIORÉS
    // ═══════════════════════════════════════════════════

    private PdfFont getFont(boolean bold) {
        try {
            String fontName = bold ? "Helvetica-Bold" : "Helvetica";
            return PdfFontFactory.createRegisteredFont(fontName);
        } catch (Exception e) {
            try {
                return PdfFontFactory.createFont();
            } catch (Exception e2) {
                return null;
            }
        }
    }

    private Cell creerKpiCell(String titre, String valeur, String sousTitre,
                               Color couleur, PdfFont regular, PdfFont bold) {
        Cell cell = new Cell().setBorder(new SolidBorder(GRIS_CLAIR, 1))
                .setPadding(10).setTextAlignment(TextAlignment.CENTER)
                .setBackgroundColor(GRIS_CLAIR);
        cell.add(new Paragraph(titre)
                .setFont(regular).setFontSize(9).setFontColor(GRIS_MOYEN));
        cell.add(new Paragraph(valeur)
                .setFont(bold).setFontSize(18).setFontColor(couleur)
                .setMarginTop(4).setMarginBottom(2));
        cell.add(new Paragraph(sousTitre)
                .setFont(regular).setFontSize(8).setFontColor(GRIS_MOYEN));
        return cell;
    }

    private Cell creerHeaderCell(String texte, PdfFont bold) {
        return new Cell().setBackgroundColor(VERT_FONCE)
                .setPadding(6)
                .add(new Paragraph(texte)
                        .setFont(bold).setFontSize(9).setFontColor(BLANC)
                        .setTextAlignment(TextAlignment.CENTER));
    }

    private Cell creerCellule(String texte, PdfFont font) {
        return new Cell().setPadding(4)
                .setBorder(new SolidBorder(GRIS_CLAIR, 0.5f))
                .add(new Paragraph(texte).setFont(font).setFontSize(9).setFontColor(GRIS_FONCE));
    }

    private Cell creerCelluleValeur(String texte, PdfFont bold, Color couleur) {
        return new Cell().setPadding(4)
                .setBorder(new SolidBorder(GRIS_CLAIR, 0.5f))
                .setTextAlignment(TextAlignment.RIGHT)
                .add(new Paragraph(texte).setFont(bold).setFontSize(9).setFontColor(couleur));
    }

    private Table creerTableTop5(List<FuiteResumeDto> fuites, PdfFont regular, PdfFont bold, Color accentColor) {
        Table table = new Table(new float[]{0.4f, 1.5f, 2.5f, 1.2f, 1.2f});
        table.setWidth(UnitValue.createPercentValue(100));
        table.setMarginBottom(12);

        String[] headers = {"#", "Tag", "Campagne", "Statut", "Coût (MAD)"};
        for (String h : headers) {
            table.addHeaderCell(creerHeaderCell(h, bold));
        }

        int rank = 1;
        for (FuiteResumeDto f : fuites) {
            // Rang
            Cell rankCell = new Cell().setPadding(4)
                    .setBorder(new SolidBorder(GRIS_CLAIR, 0.5f))
                    .setTextAlignment(TextAlignment.CENTER)
                    .setBackgroundColor(GRIS_CLAIR)
                    .add(new Paragraph(String.valueOf(rank))
                            .setFont(bold).setFontSize(9).setFontColor(accentColor));
            table.addCell(rankCell);

            table.addCell(creerCellule(f.getNumeroTag() != null ? f.getNumeroTag() : "Sans tag", regular));
            table.addCell(creerCellule(f.getCampagneNom(), regular));
            table.addCell(creerCellule(formaterStatut(f.getStatut()), regular));
            table.addCell(creerCelluleValeur(formatMonnaie(f.getCoutAnnuelEstime()), bold, accentColor));
            rank++;
        }
        return table;
    }

    private String formaterStatut(StatutFuite statut) {
        return switch (statut) {
            case A_REPARER -> "À réparer";
            case EN_COURS -> "En cours";
            case REPAREE -> "Réparée";
            case ANNULEE -> "Annulée";
            default -> statut.name();
        };
    }

    private String formatMonnaie(Double valeur) {
        if (valeur == null) return "0";
        if (valeur >= 1_000_000) {
            return String.format("%.1fM", valeur / 1_000_000);
        }
        // Espaces comme séparateur de milliers, pas de K
        return String.format("%,.0f", valeur).replace(",", " ");
    }
}

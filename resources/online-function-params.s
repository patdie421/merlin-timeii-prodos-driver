; ============================================================================
; Fonction : print_pascal
; Description : Affiche une chaîne Pascal en ligne (1er octet = longueur).
;               Utilise TSX + $0100,X pour lire/modifier l'adresse de retour
;               sans dépendre de la profondeur actuelle de la pile.
; Entrées     : Chaîne Pascal placée juste après le JSR
; Sorties     : Aucune
; Modifie     : Aucun registre (A, X, Y et ptr_inline sont restaurés)
; ============================================================================
print_pascal:
    ; 1. Sauvegarde des registres et du pointeur ZP sur la pile
    pha                 ; +5
    txa
    pha                 ; +4
    tya
    pha                 ; +3
    lda ptr_inline
    pha                 ; +2
    lda ptr_inline+1
    pha                 ; +1 (Sommet de la pile après ces 5 PHA)

    ; État relatif de la pile à partir de X (après TSX) :
    ; $0100 + X -> [Prochain octet libre]
    ; $0101 + X -> ptr_inline+1 (sauvegardé)
    ; $0102 + X -> ptr_inline   (sauvegardé)
    ; $0103 + X -> Y            (sauvegardé)
    ; $0104 + X -> X            (sauvegardé)
    ; $0105 + X -> A            (sauvegardé)
    ; $0106 + X -> Adresse de retour (Lo) = Adresse de l'octet de longueur - 1
    ; $0107 + X -> Adresse de retour (Hi)

    ; 2. Récupération de l'adresse de retour
    tsx
    lda $0106,x
    sta ptr_inline
    lda $0107,x
    sta ptr_inline+1

    ; 3. Lecture de la longueur de la chaîne
    ; Rappel : JSR empile (Adresse_Données - 1).
    ; Avec Y = 1, (ptr_inline),Y pointe directement sur le 1er octet de données !
    ldy #$01
    lda (ptr_inline),y  ; Lit l'octet de longueur (N)
    beq @fin            ; Si longueur = 0, rien à afficher (Y vaut déjà 1, parfait)

    sta @compteur+1     ; Auto-modification propre ou utilisation de X (voir note)
                        ; Ici, utilisons X comme compteur pour garder le code 100% ROM/RAM safe :
    tax                 ; X = nombre de caractères restants à afficher (N)

    ; 4. Boucle d'affichage des N caractères
@loop:
    iny                 ; Y passe à 2 (1er caractère), puis 3, 4...
    lda (ptr_inline),y  ; Lit le caractère
    jsr print_char      ; Affiche le caractère (doit préserver X et Y !)
    dex                 ; Décrémente le compteur de caractères
    bne @loop           ; Continue tant que X != 0

@fin:
    ; 5. Calcul et mise à jour de la nouvelle adresse de retour
    ; À la sortie de la boucle :
    ; - Si N = 0 : Y = 1 (pointe sur l'octet de longueur).
    ; - Si N > 0 : Y = N + 1 (pointe exactement sur le dernier caractère de la chaîne).
    ; Dans les deux cas, (ptr_inline + Y) vaut (Adresse_Instruction_Suivante - 1) !
    ; C'est exactement ce dont RTS a besoin.

    tya                 ; Met l'offset Y dans A
    clc
    adc ptr_inline      ; Additionne Y à l'octet faible de ptr_inline
    sta ptr_inline
    bcc @no_carry
    inc ptr_inline+1    ; Ajoute la retenue à l'octet fort si dépassement de page
@no_carry:

    ; Écriture de la nouvelle adresse de retour directement dans la pile
    tsx                 ; Recharge X (au cas où print_char l'aurait modifié)
    lda ptr_inline
    sta $0106,x         ; Met à jour Retour_Lo
    lda ptr_inline+1
    sta $0107,x         ; Met à jour Retour_Hi

    ; 6. Restauration complète dans l'ordre inverse des sauvegardes
    pla
    sta ptr_inline+1    ; Restaure ptr_inline (Hi)
    pla
    sta ptr_inline      ; Restaure ptr_inline (Lo)
    pla
    tay                 ; Restaure Y
    pla
    tax                 ; Restaure X
    pla                 ; Restaure A

    ; 7. Retour à l'appelant (RTS ajoute +1 à ptr_inline et saute après la chaîne)
    rts

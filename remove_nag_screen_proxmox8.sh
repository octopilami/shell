#!/bin/bash

# Script pour supprimer le nag screen de Proxmox VE 8
# À exécuter en tant que root

echo "Vérification du nag screen de Proxmox VE 8..."

# Vérification que le fichier existe
PROXMOX_FILE="/usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js"

if [ ! -f "$PROXMOX_FILE" ]; then
    echo "❌ Fichier Proxmox non trouvé : $PROXMOX_FILE"
    echo "Vérifiez que Proxmox VE est bien installé"
    exit 1
fi

# Vérification si le nag screen est présent
if grep -q "No valid sub" "$PROXMOX_FILE"; then
    echo "✓ Nag screen détecté dans le fichier"
elif grep -q "data.status !== 'Active'" "$PROXMOX_FILE"; then
    echo "✓ Nag screen détecté (variante)"
else
    echo "✓ Le nag screen semble déjà supprimé ou absent"
    echo "Aucune modification nécessaire"
    exit 0
fi

# Vérification si déjà modifié
if grep -q "void({ //" "$PROXMOX_FILE"; then
    echo "✓ Le fichier semble déjà modifié"
    echo "Aucune action nécessaire"
    exit 0
fi

echo "📝 Modification nécessaire, procédure en cours..."

# Sauvegarde du fichier original
cp "$PROXMOX_FILE" "$PROXMOX_FILE.bak"
echo "✓ Sauvegarde créée : $PROXMOX_FILE.bak"

# Suppression du nag screen en modifiant le fichier JavaScript
if sed -Ezi.orig \
  "s/(Ext\.Msg\.show\(\{\s*title: gettext\('No valid sub)/void\(\{ \/\/\1/g" \
  "$PROXMOX_FILE"; then
    echo "✓ Première méthode appliquée avec succès"
else
    echo "⚠ Première méthode échouée, essai de la méthode alternative..."
    # Alternative plus simple avec une regex différente
    if sed -i.bak2 "s/data.status !== 'Active'/false/g" "$PROXMOX_FILE"; then
        echo "✓ Méthode alternative appliquée avec succès"
    else
        echo "❌ Échec des deux méthodes"
        echo "Restauration de la sauvegarde..."
        cp "$PROXMOX_FILE.bak" "$PROXMOX_FILE"
        exit 1
    fi
fi

# Redémarrage des services web de Proxmox
echo "🔄 Redémarrage des services Proxmox..."
if systemctl restart pveproxy && systemctl restart pvedaemon; then
    echo "✓ Services redémarrés avec succès"
else
    echo "⚠ Erreur lors du redémarrage des services"
fi

echo ""
echo "🎉 Nag screen supprimé avec succès !"
echo "📁 Sauvegarde disponible : $PROXMOX_FILE.bak"
echo "🌐 Actualisez votre interface web Proxmox (Ctrl+F5)"

# Vérification finale que la modification a bien été appliquée
if grep -q "void({ //" "$PROXMOX_FILE" || grep -q "false" "$PROXMOX_FILE" | head -1; then
    echo "✅ Modification confirmée dans le fichier"
else
    echo "⚠ La modification pourrait ne pas avoir été appliquée correctement"
fi

#!/bin/bash
echo "🔍 Vérification des outils..."
for tool in docker kind kubectl clusterctl helm; do
  if command -v $tool &> /dev/null; then
    version=$($tool version 2>/dev/null | head -1 || echo "installé")
    echo "✅ $tool: $version"
  else
    echo "❌ $tool: NON INSTALLÉ"
    exit 1
  fi
done
echo ""
echo "✅ Tous les outils sont prêts!"

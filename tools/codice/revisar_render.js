// Contrato de formato del compendio, comprobado sobre la pagina RENDERIZADA.
//
// Las auditorias de python miran los datos; esto mira lo que acaba viendo el lector. El
// fallo del marco de las citas no lo cazaba ninguna de las otras: los datos estaban bien
// y era el reconocimiento de la atribucion lo que habia dejado de funcionar.
//
// Se pega en la consola de compendio.html (o se ejecuta con el navegador de Claude) y
// recorre todas las fichas abriendolas una a una.
(async () => {
  const KB = window.HARFORD_COMPENDIUM;
  const fallos = [];
  const anota = (ficha, regla, detalle) => fallos.push({ ficha, regla, detalle });
  const esperar = ms => new Promise(r => setTimeout(r, ms));

  // marcas de markdown que NUNCA deben verse como texto
  const CRUDO = [
    [/\*\*/, 'negrita sin renderizar'],
    [/(?:^|\s)\*\S/, 'cursiva sin renderizar'],
    [/^#{1,6}\s/m, 'titulo sin renderizar'],
    [/\[[^\]]+\]\([^)]+\)/, 'enlace sin renderizar'],
    [/(?:^|\n)\s*>\s/, 'recuadro sin renderizar'],
    [/(?:^|\n)_{3,}(?:\n|$)/, 'separador sin renderizar'],
    [/\|\s*[-:]{3,}/, 'tabla sin renderizar'],
  ];

  const abrir = async (tipo, id) => {
    location.hash = '#' + tipo + '/' + id;
    window.dispatchEvent(new HashChangeEvent('hashchange'));
    await esperar(60);
    return document.querySelector('.sheet') || document.body;
  };

  const revisar = async (tipo, lista, conCita) => {
    for (const it of lista) {
      const raiz = await abrir(tipo, it.id);
      const txt = raiz.innerText || '';
      const ficha = tipo + '/' + it.name;
      for (const [re, regla] of CRUDO) if (re.test(txt)) anota(ficha, regla, (txt.match(re) || [''])[0].slice(0, 40));
      // la cita de apertura tiene que ir enmarcada, no suelta en cursiva
      if (conCita && /^\s*[*_]*[—–]/m.test((it.desc || ''))) {
        const cita = [...raiz.querySelectorAll('blockquote cite')];
        if (!cita.length) anota(ficha, 'cita de apertura sin marco', '');
      }
      // un recuadro del libro se dibuja como recuadro
      if ((it.extras || '').includes('> ') && !raiz.querySelector('aside.mdbox'))
        anota(ficha, 'recuadro del libro sin dibujar', '');
    }
  };

  await revisar('classes', KB.classes || [], true);
  await revisar('races', KB.races || [], true);
  await revisar('backgrounds', KB.backgrounds || [], false);
  await revisar('spells', (KB.spells || []).slice(0, 120), false);

  const porRegla = {};
  fallos.forEach(f => (porRegla[f.regla] = (porRegla[f.regla] || []).concat(f.ficha)));
  return { fallos: fallos.length, porRegla, muestra: fallos.slice(0, 12) };
})();

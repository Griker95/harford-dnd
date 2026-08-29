-- HarfordDnDBookText: fuente local del Libro en Markdown y lectura segura de secciones.
-- Generado desde Libro1.txt para que Epsilon pueda mostrar el texto sin acceso al disco.

HarfordDnDBookText = HarfordDnDBookText or {}

local API = HarfordDnDBookText
local SOURCE = [====[<style>
/* GLOBAL FORMATTING  */

  /* Resize page to international A4 */
  .phb {
    width: 210mm;
    height: 296.8mm;
  }
  .phb:after { content: ""; }


/* TABLE OF CONTENTS  */

  /* toc specifically wants black text. This resets the headers*/
  .toc a {
    color: inherit !important;
  }
  /* Allow dot leaders to fill remaining space but not overlap */
  .toc li span:nth-child(2) {
    width: auto;
    overflow: hidden;
    white-space: nowrap;
    display: block;
  }
  .toc li span:nth-child(2):after {
    font-family: BookSanity;
    font-size: 0,317cm;
    font-weight: normal;
    color: black;
    content:
      " ........................................"
      "........................................."
      ".........................................";
    }

  /* Style TOC page numbers*/
  .toc li span:first-child {
    float: right;
    font-family: BookSanity;
    font-size: 0,317cm;
    font-weight: normal;
    color: black;
    margin-left: 1px;
  }

  /* Adjust TOC H3 styles */
  .toc li h3 span:nth-child(2):after {
  	content: " ";
  }
  .toc li h3 {
    margin-bottom: 4px !important;
    margin-top: 10px !important;
    line-height: initial !important;
  }
  .toc li h3 span:first-child {
  	line-height: 1.8em !important;
  }

  /* Reduce TOC list indentation*/
  .toc ul ul {
  	margin-left: 10px !important;
  }
  .toc>ul>li {
    margin-bottom: initial !important;
  }


/* TABLES AND BLOCKS */

  /* Clear internal padding and add gap above for green note blocks*/
  .phb blockquote {
    padding-left: 0px;
    padding-right: 0px;
  }
  .phb blockquote { margin-top: 1em;
  }


/* INK BLOT STYLES */

  /* Root style for inkblots. Use alone, or together with
  one of the inkb lotstyle classes below. Essentially:
  <img url='{url}' class='inkblot inkblot-blue' />
  */
  .inkblot {
    position: absolute;
    mix-blend-mode: multiply;
    opacity: 0.6;
  }

  .inkblot-blue {
    filter: hue-rotate(190deg) saturate(120%)
  }

  .inkblot-green {
    filter: hue-rotate(120deg)
  }

/* PAGE STYLE */

   /* Background */
     .phb{ background-image: url('https://gmbinder.com/images/KN1O92T.png') }
     .phb{ background-size: cover }

   /* Notes */
     .phb section blockquote {background-color: #f6e5d4}
     .phb hr + section blockquote tr:nth-child(odd) td {background-color: transparent;}

   /* Tables */
     table tr:nth-child(odd) td {background-color: #cccccc}

   /* Footer */
     .phb .pageNumber {color: rgba(0, 0, 0, 0.5)}
     .phb .footnote {color: rgba(0, 0, 0, 0.5)}
     .phb:nth-child(odd):after{ 
       content          : '';
       position         : absolute;
       bottom           : -7px;
       left             : 10px;
       z-index          : -1;
       height           : 336px;
       width            : 100%;
       background-image : url('https://www.gmbinder.com/images/bNTz1nk.png');
       background-size  : cover;
   }

   .phb:nth-child(even):after{ 
       content          : '';
       position         : absolute;
       bottom           : -7px;
       left             : -10px;
       z-index          : -1;
       height           : 336px;
       width            : 100%;
       background-image : url('https://www.gmbinder.com/images/6NCzAN0.png');
       background-size  : cover;
   }

   /* Page Number */
   .phb .pageNumber{
       position   : absolute;
       bottom     : 30px;
       width      : 50px;
       text-align : center;
   }
   .phb:nth-child(even) .pageNumber{
       left      : 12px;
   }
   .phb:nth-child(odd) .pageNumber{
       right      : 12px;
   }

   .phb .pageNumber.auto{
       position   : absolute;
       bottom     : 41px;
       width      : 50px;
       text-align : center;
   }
   .phb:nth-child(even) .pageNumber.auto{
       left      : 12px;
   }
   .phb:nth-child(odd) .pageNumber.auto{
       right      : 12px;
   }

/* FRONT PAGE STYLES */

  .cover-header-container {
    display: block;
    position: absolute;
    width: 100%;
    top: 80px;
    left: 0;
    right: 0;
    clear: both;
  }

  .cover-header-logo {
    display: block;
    width: 700px;
    margin: auto;
  }

  .cover-header-divider {
    display: block;
    width: 580px;
    margin: -12px auto -6px;
  }

  .cover-header-title {
    display: block;
    width: 700px;
    margin: auto;
    color: white;
    font-family: NodestoCaps,nodesto,sans-serif;
    font-weight: normal;
    font-size: 72px;
    line-height: 72px;
    text-align: center;
    text-shadow: 2px 2px 4px #000, -2px 2px 4px #000, 2px -2px 4px #000, -2px -2px 4px #000;
  }

  .cover-footer-container {
    display: block;
    position: absolute;
    width: 100%;
    bottom: 28px;
    left: 0;
    right: 0;
    clear: both;
  }

  .cover-footer-subtitle,
  .cover-footer-version {
    display: block;
    width: 500px;
    margin: auto;
    color: white;
    font-family: NodestoCaps,nodesto,sans-serif;
    font-weight: normal;
    text-align: center;
    text-shadow: 1px 1px 2px #000, -1px 1px 2px #000, 0px 0px 2px #000;
  }
  .cover-footer-subtitle {
    font-size: 28px;
    line-height: 28px;
  }
  .cover-footer-version {
    margin-top: 16px;
    font-size: 20px;
    line-height: 20px;
  }

/* STAT BLOCKS */
  /* For creature statblocks within range (start and end must be specified),
     don't show a background. Used for the appendix creatures */
  .phb:nth-of-type(n+140):nth-of-type(-n+200) hr+section blockquote {
    background: none;
    border: none;
    box-shadow: none;
<style> .phb#p1:after { display:none; } </style>
<div class='cover-header'> <div style='margin-top:50px;'></div> World of Warcraft </div>
<div class='cover-header'> <div style='margin-top:100px;'></div> D&D 5º Edicion</div>
<img src='https://www.gmbinder.com/images/0PdNsAt.jpg' style='position:absolute; top:-80px; right:-500px; width:2000px' />
<img src='https://www.gmbinder.com/images/3d9m32D.png' style='position:absolute; top:1000px; right:675px; width:100px' />

\pagebreak

<div style="text-align: Center">

# Indice
</div>

<div class='toc'>

- ### [<span>4</span><span>Parte I: Personaje                                </span>](#p4)
  - #### [<span>5</span><span>Capítulo 1: Razas                              </span>](#p5)
     - [<span>5</span><span>Eligiendo una facción                            </span>](#p5)
     - [<span>6</span><span>Eligiendo una raza                               </span>](#p6)
     - [<span>6</span><span>Idiomas                                          </span>](#p6)
     - [<span>7</span><span>*Razas de la Alianza*                            </span>](#p7)
       - [<span>8</span><span>Humano                                         </span>](#p8)
       - [<span>10</span><span>Enano                                         </span>](#p10)
       - [<span>12</span><span>Elfo de la noche                              </span>](#p12)
       - [<span>15</span><span>Gnomo                                         </span>](#p14)
       - [<span>16</span><span>Draenei                                       </span>](#p16)
       - [<span>18</span><span>Huargen                                       </span>](#p18)
     - [<span>20</span><span>*Razas de la Horda*                             </span>](#p20)
       - [<span>21</span><span>Orco                                          </span>](#p21)
       - [<span>23</span><span>Renegado                                      </span>](#p23)
       - [<span>25</span><span>Tauren                                        </span>](#p25)
       - [<span>37</span><span>Trol                                          </span>](#p27)
       - [<span>39</span><span>Elfo de Sangre                                </span>](#p29)
       - [<span>31</span><span>Goblin                                        </span>](#p31)
     - [<span>33</span><span>*Razas Aliadas*                                 </span>](#p33)
       - [<span>34</span><span>Nocheterna                                    </span>](#p34)
       - [<span>36</span><span>Pandaren                                      </span>](#p36)
       - [<span>38</span><span>Elfo del Vacío                                </span>](#p38)
       - [<span>39</span><span>Vulpera                                       </span>](#p39)
  - #### [<span>##</span><span>Capítulo 2: Clases                            </span>](#p##)
     - [<span>##</span><span>Caballero de la Muerte                          </span>](#p##)
     - [<span>##</span><span>Cazador de demonios                             </span>](#p##)
     - [<span>##</span><span>Druida                                          </span>](#p##)
     - [<span>##</span><span>Cazador                                         </span>](#p##)
     - [<span>##</span><span>Mago                                            </span>](#p##)
     - [<span>##</span><span>Monje                                           </span>](#p##)
     - [<span>##</span><span>Paladín                                         </span>](#p##)
     - [<span>##</span><span>Sacerdote                                       </span>](#p##)
     - [<span>##</span><span>Pícaro                                          </span>](#p##)
     - [<span>##</span><span>Chamán                                          </span>](#p##)
     - [<span>##</span><span>Brujo                                           </span>](#p##)
     - [<span>##</span><span>Guerrero                                        </span>](#p##)
  - #### [<span>##</span><span>Capítulo 3: Trasfondos                        </span>](#p##)
     - [<span>##</span><span>Apotecario oscuro                               </span>](#p##)
     - [<span>##</span><span>Agente Doble                                    </span>](#p##)
     - [<span>##</span><span>Criado por la Facción                           </span>](#p##)
     - [<span>##</span><span>Aprendiz del Kirin Tor                          </span>](#p##)
  - #### [<span>##</span><span>Capítulo 4: Equipamiento                      </span>](#p##)
     - [<span>##</span><span>Equipo inicial                                  </span>](#p##)
     - [<span>##</span><span>Armas exóticas                                  </span>](#p##)
     - [<span>##</span><span>Herramientas y equipo de aventuras              </span>](#p##)
  - #### [<span>##</span><span>Capítulo 5: Personalización                   </span>](#p##)
     - [<span>##</span><span>Dotes especiales                                </span>](#p##)
     - [<span>##</span><span>Dotes raciales                                  </span>](#p##)

\columnbreak

- ### [<span>##</span><span>Parte II: Magia                                 </span>](#p##)
  - #### [<span>##</span><span>Capítulo 6: Hechizos                         </span>](#p##)
     - [<span>##</span><span>Listas de hechizos                             </span>](#p##)
     - [<span>##</span><span>Descripciones de hechizos                      </span>](#p##)
- ### [<span>##</span><span>Parte III: Reglas adicionales                   </span>](#p##)
 - [<span>##</span><span>Puntos de heroe                                    </span>](#p##)
 - [<span>##</span><span>Mana                                               </span>](#p##)
- ### [<span>##</span><span>Anexo A: Cambiaformas                           </span>](#p##)
- ### [<span>##</span><span>Anexo B: Compañeros                             </span>](#p##)
- ### [<span>##</span><span>Anexo C: Mapa del mundo                         </span>](#p##)
- ### [<span>##</span><span>Anexo D:                                        </span>](#p##)
</div>

<style> .phb#p3:after { display:none; } </style>

\pagebreak

<div class='partpage'>

# Parte I 
##### Creando un personaje
</div>

<style> .phb#p4:after { display:none; } </style>
<img src='https://www.gmbinder.com/images/174aZQG.jpg' style='position:absolute; top:0px; right:-980px; width:2800px' />

\pagebreak

# Capítulo 1: Razas
Los ejércitos y las facciones siempre han definido el mundo de Warcraft, y dos de las facciones más poderosas en Azeroth hoy en día son la Alianza y la Horda. La mayoría de los jugadores pertenecen a una facción o a la otra, aunque existen algunas anomalías.

## Eligiendo una facción 
Al crear un personaje, cada jugador debe elegir la facción de su personaje. Es tan importante para el héroe como su clase o trasfondo. Todos los personajes de un grupo suelen pertenecer a la misma facción.

Aunque cada raza tiene una afiliación, hay excepciones. Crear un personaje fuera de su afiliación normal puede ser un desafío, pero ofrece grandes oportunidades de interpretación para el jugador. Algunas sugerencias son las siguientes:

 - El personaje nació en la facción.
 - El personaje fue salvado o se hizo amigo de miembros de la facción.
 - El personaje huyó de su facción.
 - El personaje fue testigo de que los miembros de su facción hicieron algo que encontró reprobable.

### La Alianza
La Alianza ha demostrado ser un grupo de feroces combatientes, a menudo entregando sus vidas cuando es necesario. La facción no es un cuerpo gubernamental uniforme, sino una coalición de ayuda militar y económica mutua. La diplomacia es clave dentro de la Alianza y las decisiones se toman tradicionalmente mediante votaciones de sus miembros más influyentes. Ventormenta es la fuerza más poderosa de la multirracial Alianza. Convirtiéndose en el líder de facto de los reinos humanos restantes y forjando una alianza con el reino enano, Forjaz. Ventormenta es indiscutiblemente vista como la encargada de mantener la Alianza y sus políticas. Ventormenta es donde los miembros de la Alianza se reúnen para discutir problemas globales y defensa mutua. La mayoría de los ciudadanos de la Alianza también reconocen la Ciudad de Ventormenta como el corazón de la Alianza.


Incluso ahora los humanos son el pegamento que mantiene unida a la Alianza, siendo la raza más numerosa y diplomática de sus miembros. Los ejércitos de Ventormenta están principalmente estacionados en los Reinos del Este al sur, asegurando regiones como el Bosque de Elwynn, Villa Oscura, Páramos de Poniente y las Montañas Crestagrana, además de contar con puestos y bases en puntos clave de Lordaeron, Rasganorte y Kalimdor. Los ejércitos de Forjaz están mayoritariamente estacionados en Khaz Modan junto a sus aliados gnomos, y los ejércitos elfos de la noche defienden principalmente 
<br> <span style="margin-left:30px"></span> el norte de Kalimdor de la deforestación de
<br> <span style="margin-left:75px"></span> Vallefresno a manos de la Horda. Las fuerzas
<br> <span style="margin-left:85px"></span> draenei todavía intentan asegurar su nuevo
<br> <span style="margin-left:90px"></span> hogar en la Isla Bruma Azur y también
<br> <span style="margin-left:105px"></span> están estacionadas en Terrallende.
<br> <span style="margin-left:110px"></span> Los recientemente incorporados
<br> <span style="margin-left:120px"></span> ejércitos de Gilneas se defienden
<br> <span style="margin-left:125px"></span> de los interminables Renegados.

\columnbreak

<div style='margin-top:233px;'></div>

### La Horda 
La Horda no hace concesiones cuando se trata de la excelencia, y el poder y la ferocidad de sus guerreros son legendarios. A menudo malinterpretada como malvada, la Horda posee un fuerte código de honor y leyes estrictas para la desobediencia. Todos los miembros de la Horda deben hacer un juramento de sangre para unirse y están obligados a seguir las órdenes del jefe de guerra y apoyar al jefe de guerra si este solicita su ayuda. El puesto de jefe de guerra puede ser obtenido si el anterior jefe de guerra elige un sucesor o desafiando al jefe actual a un Mak'gora: un duelo preestablecido con armas mortales entre dos personas que sigue un procedimiento formal en presencia de testigos y que, tradicionalmente, se lucha hasta que una de las partes se rinde o muere, generalmente para resolver una disputa relacionada con un punto de honor.

El jefe de guerra puede aceptar embajadores y asesores de todas las tribus y miembros de la Horda para asegurarse de que su voz sea escuchada pero solo el jefe de guerra tiene la última palabra en asuntos que afectan a toda la Horda. Cada raza dentro de la Horda elige a un solo líder para gobernar a su pueblo y sus reinos, y también para representar a su gente en la Horda.

A pesar de su apariencia algo monstruosa, la mayoría de la Horda no es malvada; al igual que la Alianza, está compuesta por diversas facciones e individuos que poseen una amplia gama de valores y virtudes. Sin embargo, hay una expectativa que debe cumplirse al unirse a la Horda: independientemente del género o el estatus, todos deben contribuir y poner sus talentos al servicio de la Horda. Cuando la debilidad se convierte en una carga para la Horda, es deber de los fuertes tomar el control de los incompetentes y redimir a la Horda. 

*¡Lok'tar ogar! ¡Victoria o muerte!*— Estas palabras atan a uno a la Horda. Son la verdad más sagrada y fundamental para cualquier guerrero de la Horda, ya que para la Horda, el fracaso no es una opción.

Culturalmente, los orcos y tauren creen en la redención más que la mayoría de las otras razas en Azeroth y están dispuestos a dar una oportunidad a casi cualquier persona, independientemente de su reputación. Los trols parecen haber aceptado, (o al menos tolerado) a su antiguo <br> enemigo, los elfos de sangre. En gran medida
<br>debido a estas creencias, se pueden encontrar
<br>numerosas razas mortales y muchas
<br>facciones diversas al servicio de la Horda.

<img src='https://www.gmbinder.com/images/wl1T3Aj.jpg' style='position:absolute; top:0px; right:-50px; width:600px' />
<img src='https://www.gmbinder.com/images/huxbNse.png' style='position:absolute; top:-240px; right:0px; width:900px' />
<img src='https://www.gmbinder.com/images/huxbNse.png' style='position:absolute; top:0px; right:-30px; width:900px' />
<img src='https://www.gmbinder.com/images/5ItC6WX.png' style='position:absolute; top:955px; right:620px; width:230px; z-index:20' />
<img src='https://www.gmbinder.com/images/EK9lCTV.png' style='position:absolute; top:930px; right:-80px; width:240px; z-index:20' />

\pagebreak

## Eligiendo una facción
Tu elección de raza afecta a muchos aspectos diferentes de tu personaje. Establece cualidades fundamentales que existirán a lo largo de la vida de tu personaje. Ten en cuenta el tipo de personaje que deseas interpretar. Por ejemplo, un gnomo puede ser una buena opción para un pícaro sigiloso, un enano se convierte en un guerrero robusto, y un elfo puede ser un maestro de la magia arcana.

La raza de tu personaje no solo afecta tus puntuaciones de habilidad y rasgos, sino que también proporciona elementos para construir la historia de tu personaje. La descripción de cada raza incluye información para ayudarte a interpretar un personaje de esa raza, incluyendo personalidad, apariencia física, características de la sociedad y tendencias de alineamiento racial.

Estos detalles son sugerencias para ayudarte a reflexionar sobre tu personaje; los aventureros pueden diferir ampliamente de la norma para su raza. Vale la pena considerar por qué tu personaje es diferente, como una manera útil de pensar sobre el trasfondo y la personalidad de tu personaje.

### Rasgos raciales
La descripción de cada raza incluye rasgos raciales de los miembros de esa raza. Las siguientes entradas aparecen entre los rasgos de la mayoría de las razas.

#### Incremento de Caracteristica
Cada raza aumenta una o más de las puntuaciones de caracteristica de un personaje.

#### Edad
La entrada de edad indica la edad en la que un miembro de la raza es considerado un adulto, así como la esperanza de vida esperada de la raza. Esta información puede ayudarte a decidir cuántos años tiene tu personaje al inicio del juego.

#### Alineamiento
La mayoría de las razas tienen tendencias hacia ciertos alineamientos, descritos en esta entrada. Estas tendencias no son obligatorias para los personajes jugadores, pero considerar por qué tu enano es caótico, por ejemplo, en contraposición a la sociedad enana legal, puede ayudarte a definir mejor a tu personaje.

#### Tamaño
Los personajes de la mayoría de las razas son Medianos, una categoría de tamaño que incluye criaturas que miden aproximadamente entre 1,20 y 2,40 metros de altura. Los miembros de algunas razas son Pequeños (entre 60 cm y 1,20 metros de altura), lo que significa que ciertas reglas del juego los afectan de manera diferente. La regla más importante es que los personajes Pequeños tienen dificultades para manejar armas pesadas.

#### Velocidad
Tu velocidad determina la distancia que puedes moverte.

#### Idiomas
Por virtud de tu raza, tu personaje puede hablar, leer y escribir ciertos idiomas. Cada raza tiene su propio idioma, con múltiples dialectos, así como un idioma "común" que la mayoría de su facción habla y entiende. El Capítulo 4 enumera los idiomas comúnmente hablados en Azeroth.

\columnbreak

#### Subrazas
Muchas razas tienen subrazas. Los miembros de una subraza poseen los rasgos de la raza principal, además de los rasgos específicos de su subraza. Las relaciones entre subrazas varían significativamente de una raza a otra.

### Idiomas
Docenas de idiomas pueden escucharse en todo Azeroth, y cada lengua tiene dialectos y variantes regionales. Para que las razas puedan comunicarse de manera comprensible, la lengua Común es esencial. Sin embargo, otros idiomas continúan siendo ampliamente utilizados en los hogares y dentro de las fronteras de ciertas regiones.

##### Idiomas básicos
|&nbsp; Idioma      | Hablantes          | Escritura   |
|:------------------|:-------------------|:------------|
|&nbsp; Común       | Humanos            | Común       |
|&nbsp; Darnassiano | Elfos de la noche	 | Darnassiano |
|&nbsp; Draenei     | Draenei            | Eredun      |
|&nbsp; Enano       | Enanos             | Enano       |
|&nbsp; Goblin      | Goblins            | Común       |
|&nbsp; Gnómico     | Gnomos             | Común       |
|&nbsp; Viscerálico | Renegados          | —           |
|&nbsp; Orco        | Orcos              | Orco        |
|&nbsp; Pandaren    | Pandaren           | Mogu        |
|&nbsp; Shalassiano | Nocheterna         | Darnassiano |
|&nbsp; Taur-ahe    | Tauren             | Taur-ahe    |
|&nbsp; Thalassiano | Elfos nobles       | Darnassiano |
|&nbsp; Zandali     | Trols              | Zandali     |

##### Idiomas exóticos
|&nbsp; Idioma      | Hablantes            | Escritura |
|:------------------|:---------------------|:----------|
|&nbsp; Dracónico   | Dragones             | Dracónico |
|&nbsp; Eredun      | Demonios             | Eredun    |
|&nbsp; Kalimag     | Elementales          | Kalimag   |
|&nbsp; Bajo Común  | Razas monstruosas    | Común     |
|&nbsp; Ogro        | Ogros                | Ogro      |
|&nbsp; Shath'Yar   | Dioses antiguos      | Shath'Yar |
|&nbsp; Titánico    | Forjados por Titanes | Titánico  |

<img src='https://www.gmbinder.com/images/1Hhc7zP.jpg' style='position:absolute; top:700px; right:-80px; width:500px' />
<img src='https://www.gmbinder.com/images/huxbNse.png' style='position:absolute; top:200px; right:0px; width:900px; transform:scaley(-1)' />
<img src='https://www.gmbinder.com/images/huxbNse.png' style='position:absolute; top:0px; right:-30px; width:900px; transform:scaley(-1)' />

\pagebreak

<div class='cover-header'> <div style='margin-top:50px;'></div> Razas de la Alianza </div>
<style> .phb#p7:after { display:none; } </style>
<img src='https://www.gmbinder.com/images/c1ja74s.jpg' style='position:absolute; top:0px; right:0px; width:800px' />

\pagebreak

<div style='margin-top:546px'></div>

## Humano
*Nadie siente que lo merece. Porque nadie lo merece. Es gracia, pura y simple; somos inherentemente indignos, simplemente porque somos humanos. Sí, los elfos, enanos y todas las demás razas tienen sus defectos. Pero la Luz nos ama de todas formas. Nos ama por lo que a veces podemos llegar a ser en momentos raros. Nos ama por lo que podemos hacer para ayudar a los demás.*
<div style="text-align:Right"> 

*— Uther el Iluminado* &nbsp;</div>
<div style='margin-top:-5px'></div>

Los reinos humanos han existido durante miles de años, y los humanos mismos por miles más. Sus vidas cortas en comparación con otras razas los empujan a lograr tanto como puedan. Su valor, optimismo y terquedad los han llevado a construir algunos de los reinos más grandes de Azeroth, algunos de los cuales todavía permanecen en pie mil años después.

### Un amplio espectro 
Con su inclinación por la migración y la conquista, los humanos son muy diversos físicamente. No hay un humano típico. Un individuo puede medir entre 1,50 y más de 1,80 metros de altura y pesar entre 56 y 113 kilos. Los tonos de piel varían desde casi negros hasta muy pálidos, y los colores de cabello abarcan desde negro hasta rubio (pueden ser rizados, crespos o lisos); los hombres pueden lucir vello facial que puede ser escaso o abundante. Los humanos alcanzan la edad adulta al final de la adolescencia y rara vez viven un solo siglo.

\columnbreak

<br>
<div style='margin-top:438px'></div>

### Variedad en todas las cosas
Los humanos son la raza más adaptable y ambiciosa de Azeroth. Poseen gustos, valores y costumbres muy variados en los distintos reinos donde se han asentado. Cuando se establecen, permanecen: construyen ciudades destinadas a perdurar y grandes reinos capaces de sostenerse por siglos. Viven plenamente el presente, pero planifican su futuro, buscando dejar un legado duradero.

### Orgullosamente firmes
A pesar de las atrocidades sufridas, los humanos siguen siendo resistentes y valientes, totalmente comprometidos con la construcción de sociedades fuertes, el refuerzo de sus reinos y la recuperación de naciones perdidas. Los años de guerra han templado su resolución, haciéndolos más determinados que nunca. Sus valores de virtud, honor y valentía destacan en sus filas.

### Devotos
La Luz Sagrada es central en las naciones humanas, vista como la única religión y símbolo de culto, respeto y honor. Aunque es venerada ampliamente en Azeroth, los humanos fueron los primeros en usar sus poderes de manera ofensiva con la creación de los paladines. Sus reinos albergan iglesias de la Luz, dedicadas a un mundo de justicia y honor.

### Afiliación
En el pasado, unieron fuerzas con los orcos contra la Legión Ardiente, pero una vez vencido el demonio, los viejos rencores volvieron. Aunque los líderes de la Alianza y la Horda se respeten, antiguos odios raciales persisten.

Los humanos fundaron la Alianza y saben que son su piedra angular y que una buena relación de respeto entre sus miembros es clave.

<div class='footnote'>RAZAS | HUMANO</div>
<img src='https://www.gmbinder.com/images/Ke9OOwE.png' style='position:absolute; top:0px; right:-30px; width:1000px' />
<img src='https://www.gmbinder.com/images/pbSeYXZ.png' style='position:absolute; top:50px; right:0px; width:800px; transform:scalex(-1)' />
<img src='https://www.gmbinder.com/images/x6YvTEU.png' style='position:absolute; top:20px; right:240px; width:650px;transform:scalex(-1)' />

\pagebreakNum

### Nombres y etnias humanas
Los humanos no tienen nombres típicos como otras culturas, sino una gran variedad. Algunos padres eligen nombres de otros idiomas, como enano o darnassiano, pero la mayoría opta por nombres ligados a la cultura de su región o a las tradiciones de sus ancestros.

Las características culturales y físicas humanas varían según la región. Por ejemplo, vestimenta, arquitectura, cocina y literatura difieren entre Gilneas y Ventormenta. Los rasgos físicos dependen de antiguas migraciones, por lo que los humanos de los Reinos del Este presentan todas las variaciones posibles de coloración y rasgos.

Siete reinos humanos y grupos étnicos reconocidos pueden inspirar los nombres de tu personaje, sin importar su origen.

#### Alterac
Ubicados en las montañas de Alterac, los alteracos son de estatura moderada y complexión musculosa, con tonos de piel pálidos o claros. Su cabello suele ser plateado o rubio, y el color de sus ojos varía ampliamente, aunque las tonalidades claras son comunes.
<div style='margin-top:-18px;'></div>

<br>**Nombres alteraci:** *(Inspirados en Rusia)*

#### Dalaran  
Los dalarianos son personas esbeltas, de piel clara y con cabello castaño que varía desde rubio hasta casi negro. La mayoría tienen una estatura moderada y ojos azules o verdes. Sin embargo, estos rasgos no son universales. Los humanos de Dalaran provienen de todo el ancho y largo de los Reinos del Este para estudiar o buscar refugio en la ciudad flotante.
<div style='margin-top:-18px;'></div>

<br>**Nombres dalarianos:** No tienen nombres específicos para ellos, ya que la etnia de su pueblo varía mucho más allá de los humanos y los nombres son tomados de una variedad de razas.

#### Gilneas  
Los gilneanos son altos, con piel de clara a ámbar y ojos azules o grises acerados. La mayoría tienen cabello que va desde rojo oscuro o castaño claro hasta negro azabache.
<div style='margin-top:-18px;'></div>

<br>**Nombres gilneanos:** *(Inspirados en Inglaterra victoriana)*

#### Kul Tiras  
Originarios de las islas de Kul Tiras, los kul tiranos son generalmente altos y musculosos, con piel de clara a ámbar, similar a la de los gilneanos, cabello de castaño a negro, y ojos de colores claros.
<div style='margin-top:-18px;'></div>

<br>**Nombres Kul Tiranos:** *(Inspirados en Escocia e Irlanda)*

#### Lordaeron  
Extendidos a lo largo del norte de los Reinos del Este, los lordaneses son de estatura media y complexión delgada, con piel pálida. El color de su cabello y ojos varía mucho, pero el cabello plateado o claro y los ojos azules son comunes.

<br>**Nombres lordaneses:** (Masculinos) Alexi, Aurius, Gannon, Menard, Norwyn, Othmar, Urias, Wallace; (femeninos) Arenya, Diahann, Ellaine, Illucia, Jandice, Lydie, Malina, Merla; (apellidos) Barton, Camden, Godwin, Hayden

\columnbreak

<div style='margin-top:-18px;'></div>

#### Ventormenta  
Ubicados en la región sur de los Reinos del Este, los ventormentinos son de altura y complexión moderada, con tonos de piel que van del claro al bronceado. Su cabello varía ampliamente de rubio a castaño, al igual que sus ojos, aunque el marrón es el más común.
<div style='margin-top:-18px;'></div>

<br>**Nombres ventormentinos:** (Masculinos) Ander, Dungar, Harlan, Jesper, Jocryn, Maginor, Osric, Renato; (femeninos) Dalga, Einris, Ilsa, Jalane, Karrina, Laurena, Maris, Sarisse; (apellidos) Ayrole, Bolero, Cordell, Leifeld, Stanford

#### Stromgarde  
Más bajos que la mayoría de los humanos, los stromicos tienen piel pálida, contrastada por cabello castaño o negro, y ojos de colores oscuros.
<div style='margin-top:-18px;'></div>

<br>**Nombres stromicos:** (Masculinos) Adrien, Emmir, Galen, Ganar, Thoras, Tyrreth, Urnor, Wyenas; (femeninos) Amina, Céline, Clarisse, Ella, Emeline, Iris, Mara, Marine; (apellidos) Brewston, Farthing, Gilbreath, Swale, Tubal

### Rasgos humanos

&nbsp;&nbsp;&nbsp;&nbsp;***Incremento de caracteristica.*** Una caracteristica de tu elección aumenta en 2, y otra de tu elección aumenta en 1.

***Edad.*** Los humanos alcanzan la adultez a finales de la adolescencia y viven menos de un siglo.

***Alineamiento.*** Los humanos no tienden hacia ningún alineamiento en particular. Entre ellos se encuentran tanto los mejores como los peores.

***Tamano.*** Los humanos varían entre poco más de 1,50 metros hasta superar los 1,80 metros de altura y pesan un promedio de 80 kilogramos. Tu tamaño es Mediano. Para determinar tu altura y peso de forma aleatoria, usa el modificador de tamaño:
<div style="margin-top: -18px; font-family: ScalySans, sans-serif">

<br>&nbsp;&nbsp;&nbsp; ***Modificador de Tamaño:*** 2d10
<br>&nbsp;&nbsp;&nbsp; ***Altura:*** 1,20 metros + 20 cm + Mod. tamaño (cm)
<br>&nbsp;&nbsp;&nbsp; ***Peso en Kilogramos:*** 50 + (2d4 x Mod. tamaño)
</div>

<div style='margin-top:-3px;'></div>

&nbsp;&nbsp;&nbsp; ***Velocidad.*** 9 metros.

***Determinacion.*** Cuando realices una tirada de ataque, una prueba de habilidad o una tirada de salvación, puedes hacerlo con ventaja. No puedes hacerlo de nuevo hasta que termines un descanso corto o largo.

***Espiritu Humano.*** Cuando saques un 1 en una tirada de ataque, prueba de habilidad o tirada de salvación, puedes volver a tirar el dado. Debes usar el nuevo resultado, incluso si es un 1.

***Versatilidad de habilidades.*** Competencia en dos habilidades o herramientas de tu elección.

***Idiomas.*** Puedes hablar, leer y escribir Común y un idioma adicional de tu elección. Los humanos suelen aprender los idiomas de otros pueblos con los que tratan, incluyendo dialectos poco comunes. Les gusta añadir palabras de otros idiomas en su habla: maldiciones enanas, expresiones musicales darnassianas, trabalenguas gnómicos, etc.

<div class='footnote'>RAZAS | HUMANO</div>

<img src='https://warcraft.wiki.gg/images/0/0e/Human_Crest.png' style='position:absolute; top:900px; right:40px; width:350px' />

\pagebreakNum

<div style='margin-top:227px;'></div>

## Enano  
*Y aquí están el porqué y el cómo, para volver a ser <br>uno con la montaña. Porque, mirad, somos los terráneos, <br>de la tierra, y su alma es nuestra, su dolor es nuestro, su latido es nuestro. Cantamos su canción y lloramos por su <br>belleza. Porque, ¿quién no desearía volver a casa? <br>Ese es el porqué, oh hijos de la tierra.*  
<div style="text-align:Left">  

*— Tabla terránea, leída por el Rey Magni* &nbsp;</div>  
<div style='margin-top:-5px'></div>  

Su reino, rico en antigua grandeza, con salones tallados en las raíces de las montañas, el eco de picos y martillos en minas profundas y forjas rugientes, y un compromiso con el clan y la tradición, son elementos comunes que unen a todos los enanos. Dentro de las montañas de Khaz Modan, continúan con sus antiguas costumbres, ampliando la profundidad de sus salones y construyendo maravillas arquitectónicas.

### Un legado recuperado  
Los fragmentos descubiertos del pasado han <br>llevado a los enanos a un éxodo de <br>exploración sin precedentes, buscando sus<br> orígenes. Han enviado exploradores por todo <br>Lordaeron en busca de señales de los Titanes, <br>sus supuestos creadores, creyendo que su propósito <br>es explorar el mundo para encontrar más pruebas de su herencia.

Los enanos han establecido puestos de avanzada en los lugares más desolados de Azeroth. Desde allí, buscan secretos antiguos o organizan expediciones para despejar enemigos y continuar su misión de explorar y descubrir.

### Bajos y robustos  
Audaces y resistentes, los enanos son conocidos como hábiles guerreros, mineros y trabajadores de piedra y metal. Aunque miden menos de 1,50 metros de altura, los enanos son tan anchos y compactos que pueden pesar tanto como un humano de casi dos pies más de altura. Su valentía y resistencia igualan fácilmente a la de los pueblos más grandes.

La piel de los enanos varía desde un marrón oscuro hasta un tono más claro con un toque rojizo, siendo los tonos más comunes marrón claro o bronceado profundo, como ciertos tonos de la tierra. Sus parientes de hierro oscuro tienen una piel notablemente más oscura, de gris a negro carbón. Su cabello, largo pero de estilos simples, suele ser negro, gris o castaño, aunque los enanos Martillo Salvaje a menudo tienen cabello rojo. Los enanos varones valoran mucho sus barbas y las cuidan con esmero.

\columnbreak

<div style='margin-top:740px;'></div>

### Innovadores  
Los enanos son un pueblo orgulloso, severo y decidido, con una veta de bondad oculta bajo los rudos exteriores de sus robustas figuras. Su amor por la batalla, la invención y la exploración los impulsa a descubrir y desenterrar los misterios de su herencia, educándose más sobre aquellos que primero crearon la raza enana.

Aun así, se mantienen en las forjas y talleres, siempre innovando y creando formas nuevas y más efectivas de guerra. La tecnología impulsada por vapor y las armas de fuego tienen su origen en la inventiva y creatividad enana. La robusta raza es renombrada tanto por sus habilidades en combate como por su destreza como ingenieros y artesanos. 

<div class='footnote'>RAZAS | ENANO</div>

<img src='https://www.gmbinder.com/images/v7DFZZS.jpg' style='position:absolute; top:-40px; right:-350px; width:1150px' />
<img src='https://www.gmbinder.com/images/4eD5Yy6.png' style='position:absolute; top:0px; right:0px; width:900px; transform:scalex(-1)' />
<img src='https://www.gmbinder.com/images/l2uyR4M.png' style='position:absolute; top:335px; right:-55px; width:550px; transform:scalex(-1); z-index:20' />

\pagebreakNum

### Afiliación  
Los enanos son miembros de la Alianza y aliados firmes de sus fundadores humanos, habiendo luchado codo a codo en varias guerras. Aunque los elfos de la noche compartan lealtades, la mayoría de los enanos miran a los "humanos de orejas puntiagudas" con recelo, prefiriendo mantener distancia.

***Enanos de Forjaz.*** Estos enanos han sido parte de la Alianza desde su fundación en Lordaeron y siguen siendo un aliado constante para su causa.

***Enanos Martillo Salvaje.*** Estos enanos no juraron lealtad a la Alianza, sino que confiaron en sus parientes de Forjaz. Son un clan aislado que elige sus propias batallas, aunque se los ve a menudo entre soldados de Forjaz.

***Enanos Hierro Negro.*** Estos enanos lucharon contra la Alianza durante años al servicio del fallecido Señor del Fuego, Ragnaros. Su muerte dividió el clan, y muchos proclamaron a Moira como su nueva reina, uniéndose a la Alianza. Sin embargo, persisten las desconfianzas hacia los astutos Hierro Negro.

### Nombres  
Cada nombre propio enano ha sido usado y reutilizado por generaciones. Un nombre enano pertenece al clan, no al individuo. Los enanos pueden ganarse un nombre que destaque sobre el de su clan, aunque esto es raro, ya que la mayoría valora el orgullo de su clan.
<div style='margin-top:-18px;'></div>

<br>**Nombres masculinos:** Barab, Aradun, Thorin, Magni, Garrim, Wendel, Thurimar, Irmirn, Bhaduk, Gengur  
<br>**Nombres femeninos:** Chise, Helge, Ferya, Furga, Krona, Imli, Gwamde, Illia, Somdunn, Thanmu, Eniss, Nanla  
<br>**Nombres de clanes:** Thunderforge, Bronzebeard, Thornsteel, Hammergrim, Chunderstout, Broadmail, Madpride  

### Rasgos de los Enanos  

&nbsp;&nbsp;&nbsp;&nbsp;***Incremento de caracteristica.*** Constitución +2.

***Edad.*** Los enanos maduran al mismo ritmo que los humanos, pero son considerados jóvenes hasta los 40 años. En promedio, viven alrededor de 320 años.

***Alineamiento.*** La mayoría de los enanos son legales, creyendo en los beneficios de una sociedad bien ordenada. Tienden al bien, con un fuerte sentido de la equidad.

***Tamano.*** Los enanos miden entre 1,20 y 1,50 metros y pesan alrededor de 68 kg. Tu tamaño es Mediano. Para determinar tu altura y peso de forma aleatoria, usa el modificador de tamaño:
<div style="margin-top: -18px; font-family: ScalySans, sans-serif">

<br>&nbsp;&nbsp;&nbsp; ***Modificador de Tamaño:*** 2d4  
&nbsp;&nbsp;&nbsp; ***Altura:*** 1 metro + 20 cm + Mod. tamaño (cm)  
&nbsp;&nbsp;&nbsp; ***Peso en Kilogramos:*** 55 + (2d6 x Mod. tamaño)  
</div>

<div style='margin-top:-3px;'></div>

&nbsp;&nbsp;&nbsp; ***Velocidad.*** 7,5 metros. No se reduce al llevar armadura pesada.

***Vision en la Oscuridad.*** Puedes ver en luz tenue hasta 18 metros como si fuera luz brillante, y en oscuridad como si fuera luz tenue, sin distinguir colores, solo tonos de gris.

\columnbreak

&nbsp;&nbsp;&nbsp; ***Entrenamiento de Combate Enano.*** Competencia con el hacha de batalla, el hacha de mano, el martillo de guerra, pistolas y rifles.

***Conocimiento de la Piedra.*** Cuando hagas una prueba de Historia relacionada con el origen de la mampostería, se te considera competente y sumas el doble de tu bono de competencia.

***Idiomas.*** Puedes hablar, leer y escribir Común y Enano. El idioma enano es fuerte, con consonantes duras y sonidos guturales, que a menudo se filtran en cualquier otro idioma que un enano pueda hablar.

***Subraza.*** Las divisiones antiguas entre los enanos han resultado en tres subrazas principales: enanos de Forjaz, enanos Martillo Salvaje y enanos Hierro Negro.

#### Enano de Forjaz  
Eres fuerte y resistente, capaz de soportar el frío de Dun Morogh y el peso de la batalla. Se les conoce por su destreza militar y rara vez retroceden ante una pelea.

***Incremento de caracteristica.*** Fuerza +1.

***Dureza Enana.*** Tus PG máximos aumentan en 1, y se incrementan en 1 cada vez que subes de nivel.

***Forma de Piedra.*** Puedes usar tu reacción cuando recibes un ataque cuerpo a cuerpo visible para ganar resistencia al daño contundente, perforante y cortante hasta el final de tu próximo turno. No puedes volver a usarlo hasta completar un descanso largo.

#### Enano Martillo Salvaje  
Tienes un espíritu libre. Se sienten más cómodos en el aire que en la tierra.

***Incremento de caracteristica*** Sabiduría +1.

***Residencia en Altura.*** Estás acostumbrado a grandes altitudes, incluyendo más de 6,000 metros, y adaptado al frío.

***Valentia Irrazonable.*** Ventaja en tiradas de salvación contra el miedo.

***Domador Natural.*** Competencia en Afinidad Animal y en tiradas hechas hacia grifos.

#### Enano Hierro Negro  
Tienes un temperamento ardiente y determinación feroz. Sirvieron al Señor del Fuego Ragnaros, ganando afinidad con las llamas.

***Incremento de caracteristica.*** Inteligencia +1.

***Sangre de Fuego.*** Puedes lanzar el conjuro *Restablecimiento menor* en ti mismo una vez al día.

***Forjado en Llamas.*** Resistencia al daño por fuego.

***Vision en la Oscuridad Superior.*** Tu visión en la oscuridad es de 36 metros.

<img src='https://warcraft.wiki.gg/images/0/0a/Dwarf_Crest.png' style='position:absolute; top:800px; right:40px; width:350px' />

<div class='footnote'>RAZAS | ENANO</div>


\pagebreakNum

<div style='margin-top:296px'></div>

## Elfo de la Noche  
*La oscuridad nos cubrió al principio, y no podíamos ver. Clamamos por guía y la luna brilló intensamente sobre nosotros. Su suave luz no solo iluminó la noche, sino que también nos confortó. Su luz nos tocó desde dentro, permitiéndonos ver incluso cuando la luna no era visible...*  
<div style="text-align:Right">  

*— Tyrande Susurravientos* &nbsp;</div>  
<div style='margin-top:-5px'></div>  

Orgullosos y antiguos, los kaldorei gobernaron Azeroth como una nación poderosa. Fueron los primeros en estudiar la magia, liberándola durante la Guerra de los Ancestros. Desde entonces, la mayoría han abandonado lo arcano por el caos que trajo, centrando su atención en la fuerza bruta o el poder de la naturaleza.

### Naturaleza Graciosa  
De gran estatura, los elfos de la noche son de los más altos de Azeroth, con cuerpos esbeltos y musculosos y orejas largas. Su piel varía en tonos de azul, desde azul cielo hasta azul profundo, y el cabello abarca verdes, azules o púrpuras oscuros. Los tatuajes faciales, a menudo con motivos animales o de hojas, son un rito de paso a la adultez.

Sus ojos brillan con un resplandor dorado o plateado tenue. Desde la Gran División, el dorado es más común, un signo de conexión con la naturaleza y el druidismo. Los elfos de ojos plateados suelen ser vistos como renegados por su vínculo con lo arcano.

### Creencia en los Ancestros  
Los elfos de la noche tienen lazos con los seres antiguos de Azeroth y una profunda devoción a la diosa Elune, con templos y órdenes en su honor. Las Hermanas de Elune lideran su ejército y su civilización.

Pese a que Elune es suprema, también veneran a los dioses salvajes, guardianes que ayudaron en la Guerra de los Ancestros. Sin su intervención, los elfos de la noche habrían perecido.

\columnbreak

<div style='margin-top:570px;'></div>

### Perspectiva Atemporal  
Los elfos de la noche pueden vivir miles de años, dándoles una perspectiva amplia sobre eventos que podrían inquietar más a las razas de vida corta. Suelen mostrarse más curiosos que codiciosos y se mantienen distantes ante lo trivial. Al perseguir un objetivo, los elfos pueden ser implacables y enfocados, aunque toman su tiempo para hacer amigos o enemigos.

Como ramas de un árbol joven, son flexibles ante el peligro. Confían en la diplomacia antes de recurrir a la violencia, pero cuando es necesario, muestran su habilidad con la espada, el arco, la estrategia y las fuerzas de la naturaleza.

<div class='footnote'>RAZAS | ELFO DE LA NOCHE</div>

<img src='https://www.gmbinder.com/images/zD8Zxsp.jpg' style='position:absolute; top:-100px; right:0px; width:800px' />
<img src='https://www.gmbinder.com/images/L60ii4e.png' style='position:absolute; top:-40px; right:0px; width:900px; transform:scaleY(-1)' />
<img src='https://www.gmbinder.com/images/LkQ3kXH.png' style='position:absolute; top:40px; right:-75px; width:500px' />

<img src='https://warcraft.wiki.gg/images/c/c6/Night_Elf_Crest.png' style='position:absolute; top:810px; right:40px; width:350px' />

\pagebreakNum

### Afiliación  
Los elfos de la noche son miembros de la Alianza, a la que se unieron tras el Reinado del Caos, una guerra con consecuencias terribles para ellos y su tierra. Aunque todos en la Alianza se oponen a los orcos, pocos los odian tanto como los elfos de la noche, culpándolos por la destrucción de sus bosques y la corrupción del malvil en El Bosque del Ocaso.

#### Un Odio Ancestral  
Los elfos de la noche recuerdan las atrocidades causadas por los elfos Altonato durante la Guerra de los Ancestros y desconfían profundamente de la magia arcana. Miran a los elfos nobles y elfos de sangre con desdén y sospecha. Sin embargo, en situaciones extremas, han demostrado ser capaces de colaborar por necesidad.

### Nombres de los Elfos de la Noche  
Los nombres de los elfos de la noche tienen significados ocultos y suelen derivar del darnassiano. Los apellidos son raros y provienen de hazañas ancestrales, siendo un motivo de orgullo mantenerlos.
<div style='margin-top:-5px;'></div>

**Nombres masculinos:** Alegorn, Daros, Eiron, Mathrengyl, <br>&nbsp;&nbsp;&nbsp; Mardant, Gasul, Lanoth, Khardona, Andissiel, Sillarn  
<br>**Nombres femeninos:** Astaia, Saelienne, Jeen'ra, Lelanai, <br>&nbsp;&nbsp;&nbsp; Keina, Alathea, Lotherias, Cordessa, Aquinne  
<br>**Apellidos:** Moonlance, Shadewhisper, Nightrunner, <br>&nbsp;&nbsp;&nbsp; Bearwalker, Briarbow, Moonblade, Proudstrider  

### Rasgos de los Elfos de la Noche

&nbsp;&nbsp;&nbsp;&nbsp;***Incremento de caracteristica.*** Destreza +2 y Sabiduría +1.

***Edad.*** Alcanzan la madurez física al ritmo de los humanos, pero no se consideran adultos hasta los 100 años y pueden vivir miles de años.

***Alineamiento.*** Su conexión con la naturaleza los lleva hacia el bien y aprecian la libertad, con un toque de caos.

***Tamano.*** Miden entre 2,10 y 2,40 metros, pesando entre 90 y 110 kg. Tamaño mediano. Para determinar al azar:  
<div style="margin-top: -18px; font-family: ScalySans, sans-serif">

<br>&nbsp;&nbsp;&nbsp; ***Modificador de Tamaño:*** 2d8  
&nbsp;&nbsp;&nbsp; ***Altura:*** 2 m + 18 cm + Mod. tamaño (cm)  
&nbsp;&nbsp;&nbsp; ***Peso (kg):*** 63 + (2d6 x Mod. tamaño)  
</div>

<div style='margin-top:-3px;'></div>

&nbsp;&nbsp;&nbsp; ***Velocidad.*** 10,5 metros.

***Vision en la Oscuridad Superior.*** Puedes ver en penumbra hasta 36 metros como luz brillante y en oscuridad como penumbra, todo en un tono violeta.

***Entrenamiento con Armas Kaldorei.*** Competencia con arco largo, espada lunar, glaive lunar y glaive de guerra.

***Sentidos Agudos.*** Competencia en Percepción.

***Mascara de lo Salvaje.*** Puedes ocultarte cuando estás ligeramente cubierto por elementos naturales.

***Fusion con las Sombras.*** Ventaja en tiradas de Sigilo al estar completamente oculto por la oscuridad.

***Idiomas.*** Hablas, lees y escribes Común y Darnassiano. Este idioma es fluido y complejo, con canciones y poemas famosos entre otras razas.


<img src='https://www.gmbinder.com/images/CmjXePR.jpg' style='position:absolute; top:-20px; right:-230px; width:785px' />
<img src='https://www.gmbinder.com/images/E8GrMME.png' style='position:absolute; top:0px; right:-20px; width:900px' />

<div class='footnote'>RAZAS | ELFO DE LA NOCHE</div>

\pagebreakNum

<div style='margin-top:340px'></div>

## Gnomo  
*¿Nunca lo entendiste, verdad? Es nuestra lealtad <br>a los amigos la que nos da nuestra verdadera y mayor fuerza... mis amigos. <br>Es un poder que los números no pueden igualar.*  
<div style="text-align:Right">  

*— Gelbin Mekkatorque*<span style="margin-right:100px"></span></div>  
<div style='margin-top:-5px'></div>  

Los gnomos son una raza diminuta y nervuda de ingenieros que viven bajo tierra. Durante la Segunda Guerra, construyeron vehículos y artilugios para la Alianza, como submarinos y máquinas voladoras, para combatir a la Horda. Son grandes mecánicos e inventores, reconocidos por su conocimiento y naturaleza excéntrica. Los gnomos tenían una ciudad, Gnomeregan, construida en la Montaña de Forjaz. Pero los troggs invasores la destruyeron y masacraron a sus habitantes.

Muchos sobrevivientes se trasladaron a Khaz Modan y ahora viven con los enanos de Dun Morogh, mientras que algunos viajaron con sus amigos enanos a Kalimdor.

Los gnomos aún están recuperándose de la destrucción de su ciudad natal y son reacios a abandonar la seguridad de los túneles enanos. La mayoría de los gnomos en Kalimdor permanecen recluidos en Bael Modan.

### Expresión Alegre  
A pesar de la decimación de su raza y la destrucción de su ciudad, los gnomos son amables y de buen corazón. Hacen amigos con facilidad; muchos encuentran difícil no querer a un gnomo. Su energía y entusiasmo por la vida brilla en cada centímetro de su pequeño cuerpo. Miden un poco más de 90 cm y pesan entre 18 y 20 kg. Sus rostros bronceados o marrones suelen estar adornados con amplias sonrisas y ojos brillantes de emoción. Su cabello claro tiende a despeinarse en todas direcciones, reflejando su curiosidad insaciable.

La personalidad de un gnomo se refleja en su apariencia. Aunque el cabello de los varones es salvaje, su barba está cuidadosamente recortada y con frecuencia estilizada. Su ropa, a menudo de tonos tierra, está adornada con bordados o gemas brillantes.

\columnbreak  

<div style='margin-top:525px'></div>  

### Ingenieros Excepcionales  
Los gnomos tienden a diseñar dispositivos complicados que suelen ser seguros. Dedican tanto tiempo a planificar como a ejecutar proyectos. Si algo falla, investigan el porqué e intentan arreglarlo. Si tienen éxito, seguirán perfeccionándolo durante años. Sus diseños destacan por su complejidad y baja tasa de fallos, salvo en los casos que involucran energía caótica, en los que toman precauciones para evitar desastres fatales.

A diferencia de los goblins, que se rinden ante un fracaso, los gnomos perseveran hasta resolver el problema. Esto hace que sus invenciones tengan una tasa de fallo mucho menor que las goblins.

### Afiliación  
Los gnomos son miembros de la Alianza. Su origen compartido y proximidad con los enanos de Forjaz han forjado una gran amistad entre ambas razas. Lucharon contra la Horda en la Segunda Guerra y guardan rencor a los orcos, pero su naturaleza amable y perdonadora les permite dejar atrás los viejos odios.

Tienen poca opinión sobre las razas de Kalimdor, ya que aún no han pasado suficiente tiempo en el continente para formarse una impresión sólida.

<div class='footnote'>RAZAS | GNOMO</div>

<img src='https://www.gmbinder.com/images/8cYzWBs.jpg' style='position:absolute; top:0px; right:0px; width:1000px; transform:scalex(-1)' />

<img src='https://warcraft.wiki.gg/images/f/fa/Gnome_Crest.png' style='position:absolute; top:0px; right:400px; width:350px' />

<img src='https://www.gmbinder.com/images/L60ii4e.png' style='position:absolute; top:50px; right:0px; width:800px; transform:scaley(-1)' />
<img src='https://www.gmbinder.com/images/Vsq5oIs.png' style='position:absolute; top:-160px; right:-100px; width:650px' />

\pagebreakNum

&nbsp;&nbsp;&nbsp; ***Gnomos de Gnomeregan.*** Estos gnomos han sido parte de la Alianza desde la Primera Guerra, uniéndose a la causa junto a sus aliados enanos. Aunque su ciudad fue tomada por los troggs y gran parte de su población quedó dispersa, su lealtad y capacidad de innovación los mantuvo como un aliado esencial.

***Mecagnomos.*** Durante siglos, estos gnomos permanecieron aislados, mejorando sus cuerpos y mentes con modificaciones mecánicas. Al buscar la ayuda de la Alianza para detener los planes del Rey Mecandria, se reunieron con sus parientes de Gnomeregan tras el fin de su tiranía. Aunque comparten muchas cualidades con los gnomos tradicionales, son más cautos con sus invenciones, conscientes de los peligros que puede acarrear un mal uso de la tecnología.

#### Gnomos y Goblins  
Los gnomos consideran a los goblins no como enemigos, sino como rivales de ingenio. Esta rivalidad amistosa, pero competitiva, los lleva a enfrentamientos tanto amistosos como intensos para demostrar quiénes son los mejores inventores y creadores del mundo.

### Nombres  
Los gnomos reciben un nombre al nacer y raramente lo cambian. Aunque nacen con el apellido familiar, se espera que cada gnomo logre hazañas personales que puedan reflejarse en un nuevo apellido, símbolo de su ingenio y logros.
<div style='margin-top:-18px;'></div>

<br>**Masculinos:** Grobnick, Kazbo, Hagin, Snoonose, Mikosh, Kebos, Otlak, Ciklin, Therlick, Finlis, Iklirn
<br>**Femeninos:** Beggra, Nefti, Sorassa, Gamash, Biskil, Munkull, Inku, Fixi, Mekin, Mitkla, Dapeek
<br>**Apellidos:** Spinpistol, Airslicer, Bombtosser, Greatgear, Togglefield, Luyckbreak, Stormhammer  

### Rasgos de los Gnomos  
Tu personaje gnomo tiene los siguientes rasgos raciales:

***Incremento de Caracteristica.*** Inteligencia +2.

***Edad.*** Los gnomos maduran al mismo ritmo que los humanos, pero suelen establecerse en la vida adulta alrededor de los 40 años. Pueden vivir entre 350 y 500 años.

***Alineamiento.*** Generalmente bondadosos, los gnomos se inclinan hacia el bien. Incluso los gnomos traviesos son más juguetones que malvados, y los que se desvían hacia el mal suelen ser víctimas de una idea obsesiva o una locura.

***Tamano.*** Los gnomos miden entre 90 cm y 1,20 metros y pesan alrededor de 18 a 20 kg. Tu tamaño es Pequeño.  
<div style="margin-top: -18px; font-family: ScalySans, sans-serif">

<br>&nbsp;&nbsp;&nbsp; ***Modificador de Tamaño:*** 2d4  
&nbsp;&nbsp;&nbsp; ***Altura:*** 90 cm + Mod. tamaño (cm)  
&nbsp;&nbsp;&nbsp; ***Peso en kg:*** 16 + (1 x Mod. tamaño)  
</div>

<div style='margin-top:-3px'></div>

&nbsp;&nbsp;&nbsp; ***Velocidad.*** 7,5 metros.

\columnbreak

&nbsp;&nbsp;&nbsp;&nbsp;***Conocimientos del ArtIfice.*** Añade el doble de tu bono de competencia en pruebas de Inteligencia (Historia) relacionadas con objetos mágicos, alquímicos o tecnológicos.

***Escapista.*** Puedes usar la acción de Desenganche como una acción adicional cada turno. Además, tienes ventaja en pruebas y tiradas de salvación para evitar o finalizar la condición de apresado.

***Idiomas.*** Puedes hablar, leer y escribir Común y Gnómico. El idioma gnómico comparte el alfabeto enano y es famoso por sus tratados técnicos y su vasto conocimiento del mundo natural.

***Subraza.*** Existen dos subrazas principales de gnomos en la Alianza: los gnomos de Gnomeregan y los mecagnomos. Elige una.

#### Gnomo de Gnomeregan  
Estos gnomos poseen mentes brillantes y una disposición alegre, a pesar de haber sufrido traición, desplazamiento y casi la extinción. Su optimismo frente a la adversidad representa un espíritu inquebrantable.

***Incremento de Caracteristica.*** Carisma +1.

***Mente Expansiva.*** Añade la mitad de tu bono de competencia en cualquier prueba de Inteligencia que no tenga tu competencia.

***Ingenieria Gnomica.*** Tienes competencia con herramientas de artesano (herramientas de artesano). Puedes crear pequeños dispositivos con efectos simples, que requieren mantenimiento cada 24 horas o al final de un descanso corto o largo.

#### Mecagnomo  
Los mecagnomos han mejorado sus cuerpos con maravillas mecánicas. Aunque comparten la curiosidad de sus parientes, son más precavidos debido a su historia con la tecnología.

***Incremento de Caracteristica.*** Constitución +1.  

***Mejoras Mecanicas.*** Elige una mejora ahora y otra al nivel 5.  
<div style='margin-top:-5px;'></div>  

**Sistema de Emergencia.** Recupera puntos de golpe igual a tu nivel + tu modificador de Constitución. Puedes usarlo cuando estés inconsciente, pero solo una vez por descanso largo.  

**Vision Mejorada.** Ves en penumbra hasta 18 metros como luz brillante y en oscuridad como penumbra, solo en tonos de gris.  

**Piernas Mecanicas.** Aumenta tu velocidad a 9 metros. Puedes duplicar tu velocidad una vez por turno.  

**Brazos Mecanicos.** Golpes desarmados causan 1d6 de daño contundente y tienes competencia con una herramienta de artesano integrada.  

**Resiliencia Metalica.** Si no llevas armadura, tu CA es 13 + tu modificador de Destreza.


<img src='https://hearthstone.wiki.gg/images/0/09/Mind_Control_Tech_full.jpg' style='position:absolute; top:700px; right:0px; width:800px' />
<img src='https://www.gmbinder.com/images/L60ii4e.png' style='position:absolute; top:130px; right:0px; width:850px' />

<div class='footnote'>RAZAS | GNOMO</div>

\pagebreakNum

<div style='margin-top:700px'></div>

## Draenei  
*En momentos de gran conflicto, alzo la vista hacia los cielos y veo lo lejos que ya hemos llegado.*  
<div style="text-align:Right">  

*— Profeta Velen* &nbsp;</div>  
<div style='margin-top:-5px'></div>  

Hace miles de años, el titán Sargeras rompió la tranquilidad de Argus al ofrecer a los eredar conocimiento y poder sin límites. Los eredar, una raza en busca de saber, aceptaron su oferta. Sargeras los envolvió en energía vil, transformándolos en seres demoníacos de la Legión Ardiente conocidos como Man'ari. El profeta Velen tuvo una visión inquietante del destino de su raza y, con la ayuda de los enigmáticos naaru, huyó de Argus junto con sus seguidores, quienes pasaron a llamarse draenei, o "Exiliados".

Los draenei se refieren a sus parientes corruptos como man'ari, que significa "Ser No Natural". Aunque ambos grupos tienen sus raíces en la raza eredar, ni los draenei ni los man'ari se consideran eredar.

\columnbreak  

<div style='margin-top:497px'></div>  

### Apariencia Alienígena  
Altos y orgullosos, los draenei no se parecen a ninguna otra raza de Azeroth. Su piel varía desde el rosa pálido hasta tonos violeta oscuro. Son ligeramente más altos que los humanos, con alturas entre poco más de 1,80 y hasta 2,40 metros. Generalmente son más musculosos que otras razas, con piernas articuladas terminadas en pezuñas y un peso que supera los 113 kg. Tanto hombres como mujeres tienen aproximadamente la misma altura, y los hombres son solo un poco más pesados.

Ambos géneros poseen tentáculos en la cabeza que forman parte de su cabello o barba, y ambos tienen cuernos, aunque es común que las hembras tengan cuernos más grandes. También tienen colas delgadas, siendo las de los machos más largas y gruesas.

Los draenei rotos, aunque comparten muchas características de sus parientes, presentan diferencias notables: sus rostros son menos estructurados y más planos. Son más bajos que los draenei del Exodar y su piel es dura y agrietada, pareciendo más humana, con piernas de una sola articulación.

### Los Divinos Naaru  
Durante el viaje de los draenei, la raza enigmática de los naaru les enseñó los caminos de la Luz, aunque ya tenían cierta experiencia gracias a Velen y T'uure. Los naaru explicaron que existían otras fuerzas en el cosmos que se oponían a la Legión Ardiente.

Los naaru otorgaron una bendición, el Don de los Naaru, a los draenei para simbolizar su conexión con la Luz. Profundamente conmovidos por las palabras de los naaru, los draenei juraron honrar la Luz y defender sus ideales.

<div class='footnote'>RAZAS | DRAENEI</div>

<img src='https://www.gmbinder.com/images/zjpuVPM.jpg' style='position:absolute; top:0px; right:0px; width:1090px;transform:scalex(-1)' />

<img src='https://warcraft.wiki.gg/images/a/aa/Draenei_Crest.png' style='position:absolute; top:130px; right:40px; width:350px' />

<img src='https://www.gmbinder.com/images/bNHsRrG.png' style='position:absolute; top:90px; right:0px; width:800px; transform:scaleY(-1)' />
<img src='https://www.gmbinder.com/images/m97J1Oq.png' style='position:absolute; top:140px; right:360px; width:500px' />

\pagebreakNum

### Afiliación  
Los draenei son miembros de la Alianza. Poco después de su aterrizaje forzoso en Azeroth, encontraron a los nobles elfos de la noche, quienes los inspiraron con relatos heroicos de la Alianza y sus victorias. Conmovidos, los draenei juraron lealtad a la Alianza. Su actitud amigable y honorable les permite llevarse bien con razas de ambas facciones, siempre que no haya rencores personales de por medio.

***Draenei del Exodar.*** Estos draenei juraron lealtad a la Alianza tras su aterrizaje forzoso en las Islas Bruma Azur. A pesar de estar lejos de los Reinos del Este y gran parte de la Alianza, se han convertido en un valioso aliado para la causa.

***Draenei Forjado por la Luz.*** Surgieron del Vacío Abisal para luchar contra la Legión Ardiente durante la Tercera Invasión de Azeroth. Fueron recibidos en la Alianza al reencontrarse con sus parientes del Exodar.

***Draenei Tabido.*** Estos draeneis son parias que no han jurado lealtad a ninguna facción en Azeroth. Habitan en el planeta destruido de Draenor y son tan propensos a colaborar con miembros de la Alianza como con la Horda.

#### Desconfianza hacia los Orcos  
Aunque los draeneis son amables y honorables con otras razas, su actitud cambia al enfrentarse a un orco. Recuerdan las atrocidades cometidas contra su pueblo en Draenor y no están dispuestos a olvidar el pasado. Los draenei sienten una profunda desconfianza, y en algunos casos odio, hacia los orcos.

### Nombres  
Los draeneis tienen dos nombres: uno al nacer y otro que adoptan al alcanzar la adultez. No existe una distinción clara entre estos nombres dentro de su cultura. Han perdido tanto a lo largo del tiempo que ya no conservan apellidos familiares.
<div style='margin-top:-18px;'></div>

<br>**Masculinos:** Meolphi, Bimerd, Hiktin, Ocdam, Nosmas, Ondut, Broruk, Oter, Lacasik, Midirgerd, Drocran  
<br>**Femeninos:** Eshaatt, Ize, Ruka, Nalre, Hahse, Efae, Nerii, Asara, Velbus, Fuma, Oren, Suhe, Vumo  

### Rasgos de los Draeneis 

&nbsp;&nbsp;&nbsp;&nbsp;***Incremento de caracteristica.*** Carisma +2.

***Edad.*** Los draenei maduran un poco más lento que los humanos, alcanzando la adultez alrededor de los 20 años. Pueden vivir miles de años, superando las edades más antiguas de los elfos de la noche.

***Alineamiento.*** La mayoría de los draenei son buenos. Los que se inclinan hacia la ley suelen ser sabios, sacerdotes, paladines, vindicadores o estudiosos. Aquellos que tienden al caos son guerreros, exploradores o luchadores.

***Tamano.*** Los draenei miden entre 2,10 y 2,40 metros y pesan entre 110 y 135 kg. Tu tamaño es Mediano. Para determinar tu altura y peso al azar:
<div style="margin-top: -18px; font-family: ScalySans, sans-serif">

<br>&nbsp;&nbsp;&nbsp; ***Modificador de Tamaño:*** 2d6  
&nbsp;&nbsp;&nbsp; ***Altura:*** 1,95 m + modificador en cm  
&nbsp;&nbsp;&nbsp; ***Peso en kg:*** 68 + (2d8 x modificador)  
</div>

\columnbreak

<div style='margin-top:-3px;'></div>

&nbsp;&nbsp;&nbsp; ***Velocidad.*** 9 metros.

***Resistencia a las Sombras.*** Resistencia al daño necrótico.

***Idiomas.*** Hablas, lees y escribes Común y Draenei. El draenei es una lengua compleja para otras razas, sin semejanza con los idiomas de Azeroth.

***Subraza.*** Existen tres subrazas: draenei del Exodar, forjados por la luz y draenei rotos. Elige una.

#### Draenei del Exodar  
Tu conexión natural con los Naaru fortalece tu vínculo con la Luz. Has huido del planeta Argus para escapar de la Legión Ardiente, exiliado durante siglos antes de llegar a las Islas Bruma Azur en Azeroth.

***Incremento de caracteristica.*** Fuerza +1.  

***Tallado de Gemas.*** Competencia con herramientas de joyero.  

***Don de los Naaru.*** Como acción, puedes tocar una criatura y hacer que recupere puntos de golpe igual a tu nivel de personaje. No puedes usar este rasgo de nuevo hasta un descanso largo.  

***Presencia Heroica.*** Puedes lanzar *heroísmo* y *favor divino* usando Sabiduría como tu habilidad de lanzamiento. Una vez lanzado, no puedes usar estos hechizos de nuevo hasta un descanso largo.

#### Draenei Forjado por la Luz  
Te has comprometido a una cruzada contra la Legión Ardiente, infundiendo tu cuerpo con la Luz Sagrada. Formas parte del Ejército de la Luz, combatiendo en el Vacío Abisal y recientemente en Azeroth.

***Incremento de caracteristica.*** Constitución +1.  

***Forjado en Luz.*** Cuando no llevas armadura, tu CA es 12 + Mod. Destreza. Puedes usar esta armadura natural si resulta mejor que cualquier armadura que lleves.  

***Resistencia Sagrada.*** Resistencia al daño radiante.  

***Juicio de la Luz.*** Conoces el truco *luz*. Al alcanzar el nivel 3, puedes lanzar *rayo guiador* una vez por descanso largo. Al nivel 5, puedes lanzar *golpe de marca* una vez por descanso largo. Sabiduría es tu habilidad para lanzar estos hechizos.

#### Draenei Tábido  
Tu conexión con los Naaru fue cortada en Draenor, dejándote como un reflejo vacío de tu pueblo. Esta separación te ha desfigurado, haciéndote un paria entre los draenei del Exodar y los forjados por la luz.

***Incremento de caracteristica.*** Sabiduría +1.

***Vision en la Oscuridad.*** Tienes visión en la penumbra hasta 18 metros como si fuera luz brillante y en oscuridad como penumbra. Solo puedes ver en tonos de gris.

***Vinculo Elemental.*** Conoces el truco *escarcha*. Al nivel 3, puedes lanzar *temblor de tierra* una vez por descanso largo. Al nivel 5, puedes lanzar *ráfaga de viento* una vez por descanso largo. Sabiduría es tu habilidad para lanzar estos hechizos.

***Paria.*** Competencia en Supervivencia.

<div class='footnote'>RAZAS | DRAENEI</div>

\pagebreakNum

<div style='margin-top:540px'></div>

## Huargen  
*Cuando dije que quería recuperar la Ciudad de Gilneas de estos Renegados, algunos dijeron que era imposible. ¡Digo que ya no dejaremos que el miedo nos controle! Durante demasiado tiempo me controló a mí, temía que si conocieran toda la verdad, me rechazarían. Ya no cedo ante el miedo. Mírenme... Ahora que saben la verdad, les pregunto, ¿quién se pondrá de pie conmigo, quién luchará a mi lado?*  
<div style="text-align:Right">  

*— Genn Cringris* &nbsp;</div>  
<div style='margin-top:-5px'></div>  

Los huargen son feroces lobos humanoides, resultado de una maldición desatada por druidas imprudentes que jugaron con poderes que los superaban. Los druidas se convirtieron en los primeros huargen, salvajes e incontrolables, y fueron sellados durante siglos cuando los elfos de la noche descubrieron que su mordida podía transmitir la maldición.  

Cuando los Renegados sitiaron el reino de Gilneas, los huargen fueron liberados para combatir a los no-muertos. Aunque efectivos, los huargen ferales no distinguían entre humanos y no-muertos. La maldición se extendió como un incendio a través de Gilneas. Conscientes de su error, los elfos de la noche ayudaron a evacuar a los gilneanos hacia Teldrassil, donde los druidas les enseñaron a controlar la maldición. Algunos gilneanos, fascinados por la magia y el druidismo élfico, aprendieron sus caminos.

\columnbreak  

<div style='margin-top:365px'></div>  

### Feroz y Vicioso  
Con sus cuerpos masivos, mezcla de humano y lobo, y garras afiladas, los huargen pueden parecer criaturas de cuentos de terror para quienes desconocen su existencia. Alcanzan alturas de 1,80 a 2,40 metros. Sus cuerpos cubiertos de pelaje suelen hacerlos parecer aún más grandes de lo que son, y pesan entre 100 y 140 kg. Hombres y mujeres tienen tamaños y complexiones similares, con la única diferencia notable siendo la melena de los machos.

El pelaje de los huargen varía en tonos de negro, gris y marrón, siendo los colores más comunes, incluso si, como humanos, tenían piel o cabello claro. Los ojos de los huargen varían, al igual que los de los humanos, desde azul claro hasta marrón oscuro.

### Más que Ferocidad  
A pesar de su apariencia salvaje, los huargen conservan muchas de las cualidades que tenían en su vida humana. La maldición siempre permanece en su sangre, dando a muchos un temperamento más corto. Sin embargo, poseen la misma compasión y determinación que los humanos, esforzándose por alcanzar metas mayores para ellos mismos, su nueva familia y su pueblo humano.

### Afiliación  
Los huargen son miembros de la Alianza. Aunque la maldición los transformó físicamente, siguen siendo humanos en esencia y miembros fundadores de la Alianza. Confían y respetan a las razas aliadas. No obstante, su gratitud hacia los elfos de la noche es incomparable, ya que sin su ayuda, seguirían siendo ferales y hostiles.

#### Odio hacia los Renegados  
Ninguna raza, ni de la Alianza ni de la Horda, confía o simpatiza con los Renegados, pero el odio gilneano hacia ellos es más profundo. Los Renegados causaron gran daño a su pueblo y llevaron al colapso del Reino de Gilneas, algo que los huargen nunca olvidarán.

<div class='footnote'>RAZAS | HUARGEN</div>
<img src='https://www.gmbinder.com/images/hc81G0c.jpg' style='position:absolute; top:-250px; right:-50px; width:1200px' />

<img src='https://warcraft.wiki.gg/images/thumb/a/ab/Worgen-Icon.png/800px-Worgen-Icon.png' style='position:absolute; top:-40px; right:40px; width:350px' />

<img src='https://www.gmbinder.com/images/L60ii4e.png' style='position:absolute; top:0px; right:0px; width:900px; transform:rotate(180deg)' />
<img src='https://www.gmbinder.com/images/nV6NTzk.png' style='position:absolute; top:120px; right:170px; width:750px; transform:scalex(-1)' />


\pagebreakNum

---

\columnbreak

### Nombres de los Huargens 
La mayoría de los huargens eran humanos gilneanos y conservan los nombres humanos. Sin embargo, algunos que perdieron su identidad tras volverse ferales eligen nuevos nombres gilneanos y apellidos que reflejan hazañas de fuerza realizadas durante su vida como huargen malditos.

<div style='margin-top:-5px'></div>

**Masculinos:** Blake, Chris, Fenegan, Gerard, James, Sean, Sebastian, Vincent, Slain, Tobias, Vitus  
**Femeninos:** Amelia, Ashley, Celestine, Loren, Mary, Melinda, Mia, Tess, Almyra  
**Apellidos Gilneanos:** Broderick, Cleese, Crowly, Godfrey,  Walden, Whitewall, Hammond, Hayward  
**Apellidos Huargen:** Cringris, Moonfang, Mistmantle, Bloodfang, Darkwalker  

### Rasgos de los Huargens

&nbsp;&nbsp;&nbsp;&nbsp;***Incremento de caracteristica.*** Fuerza +2, y Destreza +1.

***Edad.*** Los huargens envejecen como los humanos, pero aunque sus cuerpos continúan envejeciendo, nunca sienten el peso de la vejez, y luchan como si fueran humanos jóvenes.

***Alineamiento.*** Los huargens tienden al caos. Aunque su origen es humano, la infección de su sangre les ha vuelto más impredecibles.

***Tamano.*** Varían mucho en altura y complexión, la mayoría mide más de 1,80 metros y pesa alrededor de 113 kg. Tu tamaño es Mediano. Para determinar tu altura y peso al azar:  
<div style="margin-top: -18px; font-family: ScalySans, sans-serif">

<br>&nbsp;&nbsp;&nbsp; ***Modificador de Tamaño:*** 2d10  
&nbsp;&nbsp;&nbsp; ***Altura:*** 1,80 m + Mod. tamaño (cm)  
&nbsp;&nbsp;&nbsp; ***Peso en kg:*** 70 + (2d8 x Mod. tamaño)  
</div>

<div style='margin-top:-3px'></div>

&nbsp;&nbsp;&nbsp;***Velocidad.*** 9 metros. Tus garras de huargen te otorgan una velocidad de escalada de 6 metros.

***Vision en la Oscuridad.*** Puedes ver en luz tenue hasta 18 metros como si fuera luz brillante, y en la oscuridad como si fuera luz tenue. No puedes distinguir colores en la oscuridad, solo tonos de gris.

***Mordida.*** Tu mandíbula es un arma natural, con la que puedes hacer ataques desarmados. Si aciertas, infliges daño perforante igual a 1d6 + tu modificador de Fuerza.

***Oído y Olfato Agudo.*** Ventaja en las pruebas de Sabiduría (Percepción) que dependan del oído o el olfato.

***Conocimiento del Cazador.*** Competencia en una de las siguientes habilidades: Afinidad Animal, Naturaleza, Percepción, Sigilo o Supervivencia.

***Salto de Pie.*** Puedes realizar un salto largo de hasta 9 metros y un salto alto de hasta 6 metros, con o sin carrera.

***Dos Formas.*** Puedes transformarte en humano en 1 minuto. En esta forma, te ves igual que antes de la maldición. Puedes volver a la forma de huargen como una acción gratuita, y lo harás automáticamente al atacar o lanzar un hechizo ofensivo.

***Idiomas.*** Hablas, lees y escribes Común y un idioma adicional de tu elección. Los humanos suelen aprender los idiomas de otras razas con las que tratan, incluyendo dialectos oscuros, y les gusta usar palabras prestadas de otros idiomas.

<div class='footnote' style='color:lightgrey'>RAZAS | HUARGEN</div>

<img src='https://www.gmbinder.com/images/ymeA1sL.jpg' style='position:absolute; top:-70px; right:200px; width:800px' />
<img src='https://www.gmbinder.com/images/Npi5n8k.png' style='position:absolute; top:0px; right:-10px; width:900px' />

\pagebreakNum

<style> .phb#p20:after { display:none; } </style>
<div class='cover-header'> <div style='margin-top:50px;'></div> Razas de la Horda </div>
<img src='https://www.gmbinder.com/images/yymWGtB.jpg' style='position:absolute; top:0px; right:0px; width:800px' />

\pagebreak

<div style='margin-top:350px;'></div>

## Orco  
*Pretender que la corrupción demoníaca no existió es olvidar cuán devastador fue su impacto. Hacer de nosotros víctimas, en vez de reconocer nuestra participación en nuestra propia destrucción. Elegimos este camino, los orcos. Lo elegimos hasta que fue demasiado tarde para retroceder. Y, al haber tomado esa decisión, podemos, con el conocimiento del fin de aquel oscuro y vergonzoso camino, elegir no tomarlo de nuevo.*  
<div style="text-align:Right">  

*— Jefe de Guerra Thrall* &nbsp;</div>  
<div style='margin-top:-5px'></div>  

Cuando los orcos fueron liberados de la Legión Ardiente, se produjo una revolución espiritual: se liberaron del ansia de sangre que los consumía y recuperaron la paz mental y espiritual de sus ancestros. Esta nueva generación siguió a Thrall, quien reconstruyó la Horda mediante el chamanismo y las tradiciones tribales.

Aunque propensos a la ira en combate, los orcos muestran una gracia salvaje comparable al arte marcial de los elfos nobles. Hoy en día, los orcos se diferencian mucho de los que fueron esclavizados por la Legión Ardiente, quienes eran una fuerza bestial apenas controlada por la magia de los brujos.

### Individuos Conscientes  
Para los orcos, el honor en combate es esencial y otorga gran prestigio personal, impregnando cada nivel de su cultura. Ganar o perder honor es igualmente importante para todos, sin importar el rango.

Los nombres de los orcos son temporales hasta superar ciertos ritos de iniciación. Cuando se ganan honor para ellos y su clan, los ancianos les otorgan un nombre de adulto basado en sus hazañas. Aunque parecen propensos a la ira, los orcos son guiados por la sabiduría de los chamanes, reverenciados en toda la sociedad de la Horda.

Aunque muchos en la Alianza aún ven a los orcos como brutales, han creado una cultura compleja, que incluye diversas ocupaciones y razas. El liderazgo de Thrall fue clave para este cambio, aunque la Alianza tiende a subestimar su capacidad de influir en los asuntos mundiales.

\columnbreak  

<div style='margin-top:595px'></div>  

### Una Conexión Espiritual  
Desde tiempos inmemoriales, los chamanes orcos han sido una constante en la historia de los clanes. Aprender a comunicarse con los espíritus elementales de Draenor fue un logro crucial para los orcos. Los primeros en aprender el chamanismo fueron del clan Sombraluna, aunque muchos clanes aseguran que el "Primer Chamán" surgió de sus filas, aunque su verdadero origen sigue siendo incierto.

Algunos chamanes orcos adoran o al menos reconocen a la Madre Tierra, deidad benevolente adorada principalmente por los tauren.

### Apariencia Temible  
Los orcos machos son criaturas imponentes y de aspecto brutal. Pesan entre 113 y 158 kg y miden entre 1,80 y 2,10 metros de altura. Incluso las mujeres orcas son solo medio pie más bajas que los machos y poseen cuerpos musculosos y fuertes.

Los orcos suelen tener cabello y barbas ásperas, generalmente negras o marrones. Su piel varía de verde claro a un tono oliva oscuro, y sus ojos van de rojo intenso a azul pálido. Tienen narices anchas, colmillos que sobresalen de sus mandíbulas inferiores (y a veces superiores), y orejas grandes y puntiagudas. Prefieren vestir ropa de piel y usan una variedad de equipos y armaduras.

<div class='footnote'>RAZAS | ORCO</div>
<img src='https://www.gmbinder.com/images/E086d0Y.jpg' style='position:absolute; top:-50px; right:0px; width:800px' />

<img src='https://warcraft.wiki.gg/images/7/74/Orc_Crest.png' style='position:absolute; top:10px; right:400px; width:350px' />

<img src='https://www.gmbinder.com/images/L60ii4e.png' style='position:absolute; top:0px; right:0px; width:900px; transform:scaley(-1)' />
<img src='https://www.gmbinder.com/images/tPFTqoe.png' style='position:absolute; top:100px; right:0px; width:400px' />

\pagebreakNum

### Afiliación  
Los orcos son miembros clave de la Horda, la cual no existiría sin ellos. Formaron la Horda Orca antes de la Primera Guerra y la Nueva Horda durante la Tercera Guerra, forjando vínculos duraderos con razas de Kalimdor. La cultura y leyes orcas aún influyen en gran parte de la Horda.

Aunque la mayoría de los orcos están en la Horda, hay clanes que prefieren aislarse de su influencia y de otras razas. Algunos son abiertamente hostiles.

### Nombres  
Los nombres orcos suelen derivar de palabras de su lengua con significados complejos o importantes para sus familias. No existen apellidos familiares; en su lugar, la mayoría usa apellidos basados en grandes hazañas de honor.
<div style='margin-top:-18px'></div>

<br>**Masculinos:** Grom, Thrum, Drog, Gorrum, Harg, Thurg, Karg, Regg, Kavenk, Uketel, Thrarturg, Crurn  
<br>**Femeninos:** Groma, Hargu, Igrim, Agra, Dragga, Grima, Fehmo, Mohma, Sherge, Zuri, Orgis  
<br>**Titulos:** Cravensmile, Steelflame, Twinthunder, Gravepride, Aridfire, Coldbrass, Foebinder, Elfkiller  

### Rasgos de los Orcos

&nbsp;&nbsp;&nbsp;&nbsp;***Incremento de caracteristica.*** Fuerza +1 y Constitución +1.

***Edad.*** Los orcos maduran más rápido que los humanos, alcanzando la adultez alrededor de los 14 años y rara vez viven más de 75 años.

***Alineamiento.*** Los orcos tienden al caos, pero no necesariamente al mal.

***Tamano.*** Miden entre 1,80 y 2,10 metros y son musculosos, con un peso promedio de 136 kg. Tu tamaño es Mediano.  
<div style="margin-top: -18px; font-family: ScalySans, sans-serif">

<br>&nbsp;&nbsp;&nbsp; ***Modificador de Tamaño:*** 2d8  
&nbsp;&nbsp;&nbsp; ***Altura:*** 1,75 m + modificador en cm  
&nbsp;&nbsp;&nbsp; ***Peso en kg:*** 90 + (2d6 x modificador)  
</div>

<div style='margin-top:-3px'></div>

\columnbreak

&nbsp;&nbsp;&nbsp; ***Velocidad.*** 9 metros.

***Amenazante.*** Competencia en Intimidación.

***Entrenamiento con Armas Orcas.*** Competencia con hacha de mano, hacha de batalla y garra de guerra.

***Resistencia Implacable.*** Cuando te reduzcan a 0 puntos de golpe pero no te maten, puedes quedarte en 1 punto de golpe. Solo puedes usar este rasgo una vez por descanso largo.

***Idiomas.*** Hablas, lees y escribes Común y Orco. El orco es una lengua áspera y gutural, escrita con runas enanas y comunes.

***Subraza.*** Elige entre clanes cazadores, místicos o guerreros para reflejar tu entrenamiento y habilidades.

#### Clanes Cazadores  
Prefieren tácticas de emboscada, como los clanes Mano Destrozada y Foso Sangrante.

***Incremento de caracteristica.*** Destreza +1.

***Emboscador.*** Competencia en Sigilo.

***Ataque Sorpresa.*** Si sorprendes a una criatura y la atacas en tu primer turno, infliges 1d6 de daño extra (aumenta con niveles).

#### Clanes Místicos  
Raramente practican magia y suelen ser nómadas. Ejemplos: Sombraluna, Reavizatormentas.

***Incremento de caracteristica.*** Inteligencia o Sabiduria +1.

***Llamado Ancestral.*** Puedes lanzar *augurio* una vez por descanso largo.

***Conocimientos Místicos.*** Competencia en Arcano, Historia, Naturaleza o Religión.

#### Clanes Guerreros  
Prefieren el combate directo. Ejemplos: Grito de Guerra, Hoja Ardiente, Lobo Gélido.

***Incremento de caracteristica.*** Fuerza +1.

***Agresivo.*** Como acción adicional, muévete hasta tu velocidad hacia un enemigo visible.

***Ataques Salvajes.*** Al hacer un golpe crítico, tira un dado de daño adicional del arma.

<img src='https://www.gmbinder.com/images/BiY1eMt.jpg' style='position:absolute; top:820px; right:0px; width:800px' />
<img src='https://www.gmbinder.com/images/3e9S91s.png' style='position:absolute; top:-75px; right:0px; width:800px' />

<div class='footnote' style='color:lightgrey'>RAZAS | ORCO</div>

\pagebreak

<div style='margin-top:430px'></div>

## Renegados  
*La muerte no ofreció escape a las decenas de humanos que murieron durante la campaña del Rey Exánime para arrasar con la vida en Lordaeron. En su lugar, los caídos fueron levantados como no-muertos del Azote, obligados a librar una guerra contra todo y todos los que alguna vez amaron.*  
<div style='margin-top:0px'></div>  

Humanos y elfos liberados del control del Rey Exánime que los alzó. Los Renegados son una fuerza oscura y extraña, originaria de la retorcida y sombría Entrañas, nominalmente aliados de la Horda, pero sirviendo solo a su causa.

Durante la cruzada del Rey Exánime, la General Forestal elfa Sylvanas Brisaveloz cayó en combate. El príncipe Arthas la levantó como una alma en pena bajo su mando. Cuando el poder del Rey Exánime se debilitó, Sylvanas, impulsada por su furia, rompió sus cadenas. Liberó a otros no-muertos y reclutó aliados poderosos. Llamó a su nueva fuerza los Renegados, estableciendo su capital en las criptas bajo Lordaeron, ahora Entrañas.

### Una Alianza Necesaria  
Los Renegados se aliaron con la Horda por necesidad. No sienten amor por los orcos, tauren u otras criaturas vivas, pero necesitan aliados contra el Azote. Los Renegados afirman haber cambiado, pero nadie lo cree del todo. La Horda los acepta, ya que tienen un enemigo común: el Azote, aunque vigilan con desconfianza sus métodos.

Con el tiempo, su posición dentro de la Horda parece haberse solidificado. Muchos Renegados ahora muestran cierta lealtad hacia la Horda, aunque no todos.

\columnbreak  

<div style='margin-top:690px'></div>  

### Conductas Extrañas  
La cultura de los Renegados es una mezcla perversa de sus antiguas vidas como mortales y la esclavitud vivida en el Azote, teñida de odio hacia el Rey Exánime y devoción hacia su reina.

Algunos Renegados intentan recuperar su humanidad con actos bondadosos. Otros dejan que el odio se convierta en crueldad.

### Alquimistas Extremistas  
Nunca duermen ni comen, y han sido abandonados por aquellos que amaron. Los Renegados tienen prioridades brutales.

Gran parte de sus esfuerzos se enfocan en la alquimia oscura. La Sociedad Real de Boticarios ostenta gran poder en Entrañas. Se rumorea que trabajan en una plaga para exterminar al Azote y a toda criatura viva en Azeroth.

<div class='footnote'>RAZAS | RENEGADO</div>
<img src='https://www.gmbinder.com/images/suFd7Ev.jpg' style='position:absolute; top:0px; right:0px; width:850px' />

<img src='https://warcraft.wiki.gg/images/7/72/Forsaken_Crest.png' style='position:absolute; top:10px; right:400px; width:350px' />

<img src='https://www.gmbinder.com/images/L60ii4e.png' style='position:absolute; top:90px; right:0px; width:800px; transform:scaley(-1)' />
<img src='https://www.gmbinder.com/images/68gnFHN.png' style='position:absolute; top:150px; right:-70px; width:700px' />

\pagebreakNum

### Apariencia Espeluznante  
Los Renegados se ven como cadáveres desenterrados. Su piel gris y en descomposición deja ver huesos, y sus ojos sin pupilas emiten un tenue resplandor espectral. Gran parte de su musculatura ha desaparecido, dándoles un aspecto escuálido y movimientos angulosos. Aunque su resurrección los ha preservado, siguen decayendo, aunque muy lentamente.

### Afiliación  
Los Renegados son parte de la Horda, aunque la desconfianza es mutua. Su alianza nació por necesidad y no por deseo. Los Renegados intentan ayudar y calmar a los embajadores de la Horda, pero la mayoría de las familias humanas no acepta lo que han llegado a ser.

### Nombres  
Los Renegados no tienen convenciones propias de nombres. La mayoría mantiene el que tenían en vida. Aquellos que no recuerdan su nombre o desean uno nuevo suelen elegirlo al azar o inspirarse en lápidas.

### Rasgos de los Renegados  
Tu personaje Renegado tiene los siguientes rasgos raciales.

***Incremento de Caracteristica.*** Constitución +2.

***Edad.*** Los Renegados no envejecen, ya que la no-muerte detiene este proceso. Con el tiempo, la decadencia afecta su mente, trayendo efectos similares al envejecimiento.

***Alineamiento.*** Conservan su alineamiento en vida, pero tienden al caos y pocos mantienen una alineación buena tras décadas de no-muerte.

***Tamano.*** Mantienen la altura que tenían en vida, pesando entre la mitad y lo mismo que antes. Tu tamaño es Mediano. Consulta la altura y peso de humanos o elfos de sangre.

***Velocidad.*** 9 metros.

***Vision en la Oscuridad.*** Puedes ver en la oscuridad hasta 18 metros como si fuera luz tenue, y en la penumbra como si fuera luz brillante. No puedes distinguir colores, solo tonos de gris.

\columnbreak  

&nbsp;&nbsp;&nbsp; ***Descanso de la Tumba.*** Para obtener los beneficios de un descanso largo, debes realizar al menos seis horas de actividad ligera en lugar de dormir.

***Naturaleza No-Muerta.*** Tu tipo de criatura es no-muerto en lugar de humanoide y obtienes los siguientes beneficios:
<div style='margin-top:-5px'></div>

- Cuentas como humanoide para efectos que no afectan a los no-muertos.
- Tienes ventaja en tiradas de salvación contra veneno y resistencia al daño por veneno.
- No necesitas comer, beber ni respirar.
- No necesitas dormir, y la magia no puede hacerte dormir.
<div style='margin-top:-5px'></div>

&nbsp;&nbsp;&nbsp; ***Voluntad de los Renegados.*** Ventaja en tiradas de salvación contra encantamientos y efectos que vuelven a los no-muertos.

***Idiomas.*** Hablas, lees y escribes Común y Viscerálico, una forma baja de Común usada en mercados clandestinos.

***Subraza.*** Existen dos subrazas entre los Renegados: humanos y elfos.

#### Renegado Humano  
Eras un humano de Lordaeron levantado como siervo del Azote. Los Renegados humanos son mayoría en su sociedad, ocupando puestos de liderazgo y comercio.

***Incremento de caracteristica.*** Aumenta en 1 una caracteristica de tu elección.

***Determinacion.*** Puedes repetir una tirada de ataque, chequeo de habilidad o tirada de salvación con ventaja una vez por descanso corto o largo.

***Versatilidad.*** Competencia en habilidad de tu elección.

#### Renegado Elfo  
Eras un alto elfo de Quel'thalas caído ante el Azote. Los Renegados elfos suelen ocupar posiciones de poder.

***Incremento de caracteristica.*** Inteligencia +1.

***Conocimiento Arcano.*** Competencia en Arcano y puedes lanzar *detectar magia* una vez por descanso corto o largo. Usas Inteligencia como habilidad de conjuro.

***Idioma Extra.*** Hablas, lees y escribes Thalassiano.

<img src='https://www.gmbinder.com/images/M8d875w.jpg' style='position:absolute; top:400px; right:0px; width:800px' />
<img src='https://www.gmbinder.com/images/3e9S91s.png' style='position:absolute; top:-170px; right:0px; width:800px' />

<div class='footnote' style='color:lightgrey'>RAZAS | RENEGADO</div>

\pagebreak

<div style='margin-top:120px;'></div>

## Tauren  
*Nuestro pueblo ha caminado esta tierra durante muchos, muchos años, y en ese tiempo hemos aprendido mucho sobre el mundo. Nuestros aliados necesitarán buscar en nosotros sabiduría y guía. Mi padre hizo una promesa a la Horda, para saldar una deuda por el servicio que nos prestaron. Yo, por mi parte, pretendo cumplir esa promesa.*  
<div style="text-align:Right">  

*— Gran Jefe Baine Pezuña de Sangre* &nbsp;</div>  
<div style='margin-top:-5px'></div>  

Las llanuras de Kalimdor han sido hogar de estos imponentes nómadas durante mucho tiempo. Los tauren son un pueblo espiritual de chamanes, cazadores y luchadores que desarrollaron una cultura compleja sin depender de piedra, acero o conquistas. Esto no significa que los tauren sean pacifistas; cuando se enfurecen, pueden responder con brutalidad rápida y decisiva.  

Los tauren son una raza noble que abraza el mundo natural. Han dejado atrás sus raíces nómadas y se han unido en sus tierras ancestrales. Aunque son espirituales, veneran la naturaleza y respetan a los ancianos, también cuentan con guerreros poderosos dispuestos a luchar cuando es necesario. Prefieren agotar todas las opciones antes de recurrir a la batalla.  

El diálogo sabio y la reflexión cuidadosa son su primera elección antes de cualquier empresa importante, y muestran gran respeto por los sabios y ancianos. No <br> son iracundos por naturaleza, pero a veces la sed de justicia los lleva a tomar las armas con furia.  

### Raza Pacífica  
Los tauren no disfrutan del derramamiento de sangre, ya que sus profundas creencias espirituales no conciben la guerra. La mayoría de los conflictos se resuelven mediante ancianos o desafíos rituales.  

Como miembros de la Horda, han estado más involucrados en conflictos, creando demanda de guerreros y sanadores. Los tauren reflexionan sobre cada acción en el campo de batalla; quitar una vida, ya sea humana o bestia, conlleva gran significado y responsabilidad.  

### Apariencia Majestuosa  
Los tauren son grandes y musculosos, con cabezas similares a las de los toros. Los machos miden en promedio 10 pies y pesan 500 libras, mientras que las hembras son un poco más bajas y ligeras. Cuentan con marcos fuertes y cuerpos cubiertos por un pelaje suave que varía en tonos sólidos o combinados de negro, rubio, blanco o moteado.  

Todos los tauren tienen cuernos, aunque los de los machos son más prominentes que los de las hembras.  

<div class='footnote'>RAZAS | TAUREN</div>
<img src='https://www.gmbinder.com/images/tr3MMTm.jpg' style='position:absolute; top:0px; right:0px; width:1000px' />
<img src='https://www.gmbinder.com/images/E8GrMME.png' style='position:absolute; top:0px; right:0px; width:900px' />
<img src='https://www.gmbinder.com/images/kxJtn7u.png' style='position:absolute; top:450px; right:-128px; width:700px' />
<img src='https://www.gmbinder.com/images/2k2FW0N.jpg' style='position:absolute; top:-70px; right:570px; width:350px; mix-blend-mode:multiply' />

\pagebreakNum

### Afiliación  
Los tauren son miembros de la Horda. Al conocer a los orcos en Kalimdor, reconocieron en ellos hermanos espirituales debido a su conexión con los elementos. Los tauren juraron lealtad a la Horda y ven a los orcos y trolls como hermanos. Toleran a los renegados, pero desconfían de ellos, y tratan a los elfos de sangre con recelo por su contacto con la magia.  

Los tauren no guardan rencor personal hacia la Alianza y sienten temor y asombro por los elfos de la noche. Ambas razas han coexistido en Kalimdor durante siglos, y los tauren ven a los elfos como una raza mítica con un profundo poder natural.  

***Tauren de Mulgore.*** Estos tauren juraron lealtad a la Horda de Thrall cuando llegó a Kalimdor y son aliados leales de la causa.  

***Tauren de Monte Alto.*** Estos tauren vivieron aislados hasta la Tercera Invasión de la Legión Ardiente. Tras la derrota de la Legión, fueron invitados a unirse a la Horda por Baine Pezuña de Sangre.  

***Taunka.*** Estos tauren migraron por Rasganorte al ser desplazados por el Azote. Aunque son miembros de la Horda, pocos dejan Rasganorte y sus frías tierras.  

### Nombres  
El idioma tauren es fuerte y grave, lo que se refleja en los nombres de sus hijos. Los apellidos suelen ser familiares, heredados a través de generaciones. Si un tauren realiza una hazaña destacada, puede adoptar un nuevo apellido que conmemore su logro.  

**Nombres Masculinos:** Azok, Bron, Turok, Garaddon, Hruon, Etu, Jeddek, Mechi, Cochu, Huslu, Idra, Naalnish  
**Nombres Femeninos:** Argo, Serga, Grenda, Beruna, Halfa, Atepa, Chepi, Mabu, Foston, Pakuna, Halona  
**Apellidos:** Espinaoscura, Pezuñatrueno, Cornatormenta, Rompepiedras, Cazaplanicies, Caminante Espiritual  

### Rasgos de los Tauren  

&nbsp;&nbsp;&nbsp;&nbsp;***Incremento de Caracteristica.*** Fuerza +2.  

***Edad.*** Los tauren alcanzan la adultez a mitad de la adolescencia y viven en promedio hasta los 95 años, siendo raro superar el siglo.  

***Alineamiento.*** Los tauren suelen ser legales, adhiriéndose a su código tribal. Aquellos que abrazan el mal son repudiados o corrompidos.  

***Tamano.*** Los tauren miden entre 8 y 10 pies y pesan entre 400 y 600 libras. Tu tamaño es Mediano, pero te elevas sobre la mayoría de los humanoides. Para determinar tu altura y peso al azar, usa el siguiente modificador de tamaño: 
<div style="margin-top: -18px; font-family: ScalySans, sans-serif">

<br>&nbsp;&nbsp;&nbsp; ***Modificador de Tamaño:*** 2d12
<br>&nbsp;&nbsp;&nbsp; ***Altura:*** 7 pies + 11 pulgadas + Mod. tamaño (pulgadas)
<br>&nbsp;&nbsp;&nbsp; ***Peso en Libras:*** 320 + (2d10 x Mod. tamaño)  
</div>

<div style='margin-top:-3px'></div>

&nbsp;&nbsp;&nbsp;&nbsp;***Velocidad.*** 30 pies.  

***Cuernos.*** Tus cuernos son armas naturales, que puedes usar para realizar ataques desarmados. Si impactas, infliges daño perforante igual a 1d6 + tu modificador de Fuerza en lugar del daño contundente normal.  

***Construccion Poderosa.*** Cuentas como una categoría de tamaño mayor para determinar tu capacidad de carga y el peso que puedes empujar, arrastrar o levantar.  

***Entrenamiento de Armas Tauren.*** Competencia con alabarda, tótem de batalla, pistola y rifle.  

***Idiomas.*** Puedes hablar, leer y escribir Común y Taur-ahe, un lenguaje fuerte y grave, escrito en pictogramas y formas.  

***Subraza.*** Existen tres subrazas principales de tauren: tauren de Mulgore, de Altamontaña y taunka. Elige una subraza.  

#### Tauren de Mulgore  
Como tauren de Mulgore, eres el más común entre tu raza. Los tauren de Mulgore son pacíficos y respetan la naturaleza, tomando solo lo necesario para sobrevivir.  

***Incremento de Caracteristica.*** Sabiduría +1.  

***Resistencia.*** Tus PG maximos aumentan en 1 y aumentan en 1 cada vez que subes de nivel.  

***Pisoton de Guerra.*** Puedes lanzar *temblor de tierra* una vez por descanso largo, golpeando el suelo con tu pezuña. Tu habilidad para lanzar el hechizo es Fuerza.  

#### Tauren de Monte Alto  
Como tauren de Monte Alto, provienes de las Islas Quebradas. Suelen ser pacíficos y amables, con cuernos que parecen astas.  

***Incremento de Caracteristica.*** Sabiduría +1.  

***Montanes.*** Estás adaptado a grandes altitudes y climas fríos, según se describe en el *Dungeon Master's Guide*. 

***Tenacidad Rugosa.*** Puedes usar tu reacción para reducir el daño que recibes en 1d12 + la mitad de tu nivel (redondeado hacia arriba). Tras usar esta habilidad, debes completar un descanso corto o largo para usarla nuevamente.  

#### Taunka  
Como taunka, te adaptaste al clima extremo de Rasganorte y tienes menos respeto por la naturaleza.  

***Incremento de Caracteristica.*** Constitución +1.  

***Resistencia al Frio.*** Resistencia al daño por frío.  

***Atleta Natural.*** Competencia en Atletismo.  

***Caminante de la Tundra.*** Te mueves por terreno difícil de hielo o nieve sin gastar movimiento adicional.  

<div class='footnote'>RAZAS | TAUREN</div>
<img src='https://www.gmbinder.com/images/WxaNruu.png' style='position:absolute; top:700px; right:40px; width:350px' />

\pagebreakNum

<div style='margin-top:340px'></div>

## Troll
*Tu ascendencia se remonta al inicio del mundo. Grandes fueron los antiguos imperios de los trolls. Veo una chispa en tus ojos, una poderosa voluntad: deseas ser grande otra vez, ¿sí?*  
<div style="text-align:Right"> 

*— Cronista Cho* &nbsp;</div>

Los trolls de la jungla, a menudo llamados trolls Gurubashi, llevan el nombre del antiguo imperio. Su capital, Zul'Gurub, se encuentra en la Vega de Tuercespina, junto con muchas aldeas y ciudades en ruinas. La aldea Sen'jin, fundada por la tribu Lanza Negra, es el asentamiento más grande fuera de Tuercespina.  

Los trolls del bosque desprecian a todas las demás razas, especialmente a los elfos de sangre, a quienes consideran profanadores de sus tierras ancestrales. Trabajan con otros solo si sirve para eliminar a un enemigo aún más odiado. Su cultura es tribal y primitiva. Aunque no son tan violentos como los trolls de hielo, tienen una temible reputación en combate.  

Los trolls de hielo viven en climas fríos. Tienen rasgos angulares, ojos azules brillantes y piel moteada azul-blanca. Generalmente son malvados, protegen ferozmente sus territorios y atacan viajeros para obtener recursos. Practican el canibalismo, comiendo a sus enemigos caídos.  

### Canibalismo y Vudú  
El canibalismo era una práctica común entre los trolls, pero la integración a la Horda hizo que fuera mal vista y prohibida. Algunos aún lo practican, pero en secreto.  

No todos los trolls practican vudú, pero es común entre ellos. Los dioses loa les otorgaron este conocimiento. Su origen exacto es desconocido, ya que las tribus que lo dominan rara vez comparten sus secretos.

### Altos y Musculosos  
Los trolls son altos, delgados y musculosos, con colmillos afilados y orejas largas. Sus extremidades largas y ágiles los hacen excelentes cazadores.  

Tienen dos dedos y un pulgar en cada mano, y dos dedos en cada pie. Algunos poseen una uña adicional en el talón, prefiriendo andar descalzos en diversos terrenos.

\columnbreak

<div style='margin-top:594px'></div>

### Afiliación  
Los trolls son miembros de la Horda. Aunque su naturaleza salvaje y el vudú a veces generan conflictos, tienen el respeto de la Horda, especialmente de los orcos. Su lealtad y lazos de batalla fortalecen sus vínculos. No suelen odiar a la Alianza, pero su lealtad y naturaleza combativa los convierte en sus enemigos. El respeto al Jefe de Guerra los mantiene en línea.  

***Trolls de la Selva.*** Estos trolls se unieron a la Horda en las islas de la tribu Lanza Negra. Sin embargo, muchos pertenecen a la tribu Gurubashi, hostil hacia forasteros.  

***Troll Zandalari.*** Estos trolls se aliaron y luego se unieron a la Horda durante la Cuarta Guerra, cuando su hogar en Zandalar fue asediado por miembros de la Alianza.

***Trol de Bosque.*** Estos trols nunca han jurado lealtad a la Horda y, aunque han estado dispuestos a luchar junto a ella para derrotar a un enemigo común, muchos trols de bosque continúan viviendo en aislamiento entre los suyos.

***Trol de Hielo.*** Estos trols no forman parte de la Horda, y los trols de hielo continúan mostrando resistencia contra la Horda y sus propósitos, prefiriendo mantener su brutal estilo de vida antes que ajustarse a las demandas de la Horda.


<div class='footnote'>RAZAS | TROLL</div>
<img src='https://www.gmbinder.com/images/uUHrf4n.jpg' style='position:absolute; top:0px; right:0px; width:1000px' />

<img src='https://warcraft.wiki.gg/images/5/54/Troll_Crest.png' style='position:absolute; top:10px; right:370px; width:430px' />

<img src='https://www.gmbinder.com/images/bNHsRrG.png' style='position:absolute; top:0px; right:0px; width:850px; transform:rotate(180deg)' />
<img src='https://www.gmbinder.com/images/xc8uKId.png' style='position:absolute; top:160px; right:-150px; width:650px; transform:scalex(-1)' />

\pagebreakNum

### Nombres
Los trolls no reciben nombres al nacer; en cambio, un troll debe ganarse un nombre dentro de su tribu. El primer nombre de un troll generalmente contiene solo una sílaba, pero a medida que demuestran su valía repetidamente, se les añaden más sílabas antes o después de su nombre ganado.

No existen apellidos ni nombres de familia en la cultura troll, aunque algunos eligen usar el nombre de su tribu como apellido, como muestra de lealtad y orgullo. Algunos trolls usan su posición dentro de la tribu como apellido, como Cazador de Sombras o Médico Brujo.
<div style='margin-top:-18px;'></div>

<br>**Nombres Masculinos:** Vol, Ros, Mig, Gal, Traxe, Maaho, Tuben, Ju, Goz, Akash, Vithek, Tian, Vazkono, Rhas, Vog
<br>**Nombres Femeninos:** Shi, Mith, Hai, So, Ozdun, Imo, Aju, Zhokre, Xullah, Joz, Fahze, Zil, Ruso, Mooh

### Rasgos de los Trolls

&nbsp;&nbsp;&nbsp;&nbsp;***Incremento de Caracteristica.*** Constitución +1.

***Edad.*** Los trolls maduran un poco más rápido que los humanos, alcanzando la adultez alrededor de los 16 años. Aunque envejecen al mismo ritmo que los humanos, los trolls no se debilitan con la edad y pueden vivir bien más de un siglo.

***Alineamiento.*** Los trolls son una raza neutral y su alineamiento puede variar drásticamente entre subrazas. La mayoría de los trolls tienden a ser legales, con cada tribu a menudo teniendo costumbres y reglas particulares para sus miembros.

***Tamano.*** Los trolls miden entre 7 y 8 pies de alto y pesan entre 200 y 300 libras. Tu tamaño es Mediano. Para determinar tu altura y peso al azar, comienza lanzando el modificador de tamaño:

<div style="margin-top: -18px; font-family: ScalySans, sans-serif">

<br>&nbsp;&nbsp;&nbsp; ***Modificador de Tamaño:*** 2d10
<br>&nbsp;&nbsp;&nbsp; ***Altura:*** 5 pies + 8 pulgadas + Mod. tamaño (pulgadas)
<br>&nbsp;&nbsp;&nbsp; ***Peso en Libras:*** 130 + (2d6 x Mod. tamaño)
</div>

<div style='margin-top:-3px;'></div>

&nbsp;&nbsp;&nbsp; ***Velocidad.*** 30 pies. 

***Vision en la Oscuridad.*** Los trolls conservan su visión en condiciones de poca luz y oscuridad. Puedes ver en luz tenue a 60 pies como si fuera luz brillante y en la oscuridad como si fuera luz tenue. No puedes discernir colores en la oscuridad, solo tonos de gris.

***Regeneracion.*** Siempre que gastes un Dado de Golpe para recuperar puntos de golpe, recuperas puntos de golpe iguales al número lanzado más el doble de tu modificador de Constitución.

Como acción, puedes gastar un número de Dados de Golpe hasta la mitad de tu nivel, como si hubieras terminado un descanso corto. Debes completar un descanso largo para volver a usar esta característica.

***Idiomas.*** Puedes hablar, leer y escribir en Común y Zandali. El zandali es la lengua de todos los trolls. Es un lenguaje mayoritariamente silábico y transmitido de generación en generación.

***Subraza.*** Cuatro subrazas principales de trolls se encuentran en Azeroth: trolls de la jungla, trolls zandalari, trolls del bosque y trolls de hielo. Elige una de estas subrazas.

\columnbreak

#### Troll de la Jungla
Tienes conocimientos de vudú y una ferocidad que pocos de tus parientes pueden igualar. Estos trolls son supersticiosos y creen que su camino está guiado por los espíritus del mundo. Su feroz determinación solo es igualada por su astucia y destreza. Muchos consideran a los trolls de la jungla como los más peligrosos y brutales de su especie por su influencia y poder en los Reinos del Este.

***Incremento de Caracteristica.*** Constitución +1 y Sabiduría +1.

***Berserker.*** Puedes realizar un ataque con un arma o lanzar un cantrip con un tiempo de lanzamiento de una acción como acción adicional en tu turno. No puedes volver a usar esta característica hasta que completes un descanso corto o largo.

***Da Voodoo Shuffle.*** Puedes moverte a través de terreno difícil no mágico sin gastar movimiento adicional.

***Entrenamiento con Armas Troll.*** Competencia con hachas de mano, hachas de batalla, dagas y jabalinas.

#### Troll Zandalari
Tienes una conexión sin igual con los loas y antiguas tradiciones más antiguas que la mayoría de las razas. Son la raza ancestral de todos los trolls y están en el centro de la unión de trolls en su ciudad templo de Zuldazar en Zandalar. Estos trolls son más poderosos que el resto y poseen una inmensa influencia y respeto entre sus tribus.

***Incremento de Caracteristica.*** Sabiduría +2.

***Conocimiento Antiguo.*** Competencia en Historia.

***Abrazo de los Loa.*** Conoces el truco *guía*. Cuando alcances el nivel 3, puedes lanzar el conjuro *Potenciar característica* una vez al día usando Sabiduría como habilidad de lanzamiento de conjuros.

***Entrenamiento con Armas Zandalari.*** Competencia con hachas de mano, hachas de batalla, espadas largas y espadas grandes.

#### Troll del Bosque
Tienes un conocimiento agudo del mundo natural, astucia para la guerra y un odio ancestral hacia los humanos y los elfos. Estos trolls son de los que quedan del Imperio Amani, que cayó a manos de la Alianza y la Horda.

***Incremento de Caracteristica.*** Destreza +1 y Constitución +1.

***Instintos Amani.*** Competencia en una de las siguientes habilidades: Naturaleza, Sigilo o Supervivencia.

***Mascara de lo Salvaje.*** Puedes intentar esconderte incluso cuando solo estés ligeramente cubierto por follaje, lluvia intensa, nieve que cae, niebla y otros fenómenos naturales.

***Entrenamiento con Armas Troll.*** Competencia con hachas de mano, hachas de batalla, dagas y jabalinas.

#### Troll de Hielo
Como troll de hielo, eres resistente y fuerte, habituado a climas fríos. Estos trolls son bárbaros y brutales, incluso comparados con otros de su especie. Los trolls de hielo viven en condiciones extremas, donde la supervivencia es lo más importante y el más fuerte es quien gobierna.

***Incremento de Caracteristica.*** Fuerza +2.

***Piel de Nacido del Hielo.*** Resistencia al daño por frío.

***Constitucion Poderosa.*** Cuentas como una criatura de un tamaño mayor cuando determines tu capacidad de carga y el peso que puedes empujar, arrastrar o levantar.

***Entrenamiento con Armas Troll.*** Competencia con hachas de mano, hachas de batalla, dagas y jabalinas.

<div class='footnote'>RAZAS | TROLL</div>

\pagebreakNum

<div style='margin-top:425px'></div>

## Elfo de Sangre
*Debemos dejar atrás esta miseria. ¡Debemos comenzar un nuevo capítulo! Así que les digo que, a partir de este día, ¡ya no somos altos elfos! En honor a los sacrificios de nuestros hermanos y hermanas, nuestros padres y nuestros hijos, ¡a partir de este día tomaremos el nombre de nuestra línea real! ¡A partir de este día, somos sin'dorei! ¡Por Quel'Thalas!*

<div style="text-align:Right"> 

*— Kael'thas Caminante del Sol* &nbsp;</div>
<div style='margin-top:-5px'></div>

Fortalecidos por las energías del Pozo del Sol, el reino encantado de Quel'Thalas prosperó en los bosques al norte de Lordaeron. Durante la Tercera Guerra, los altos elfos fueron casi exterminados cuando la Plaga, liderada por Arthas, masacró a la población y corrompió el Pozo del Sol. Los pocos sobrevivientes, liderados por el príncipe Kael'thas, se llamaron "elfos de sangre" en honor a sus caídos.

Los elfos de sangre se volvieron adictos a las energías contaminadas del Pozo. Kael'thas, buscando una cura y venganza, recorrió el mundo, pero en Terrallende sucumbió a la corrupción de la Legión Ardiente. Al regresar a Quel'Thalas, fue asesinado por su traición. Gracias al profeta draenei Velen, la corrupción del Pozo fue erradicada, restaurándolo como una fuente de energía arcana y sagrada.

Con el renacer del Pozo del Sol, los elfos de sangre han entrado en una nueva era. Algunos aún se aferran a la magia arcana, pero otros abrazan el cambio para mejorar Quel'Thalas.

\columnbreak

<div style='margin-top:664px'></div>

### Una apariencia carmesí
Culturalmente, los sin'dorei han mantenido el aspecto de su antiguo reino de altos elfos, aunque ahora prefieren el color carmesí, en honor a su nombre. Las vestiduras, decoraciones y armaduras rojas se han vuelto más comunes desde la caída de su pueblo, representando la sangre de sus hermanos caídos en la Tercera Guerra. Los colores icónicos de los elfos de sangre son el rojo, dorado y, en menor medida, azul, todos presentes en su emblema racial: el Ícono de Sangre.

### Sociedad Orgullosa
En general, los elfos de sangre son un pueblo orgulloso, pragmático y algo nacionalista; dan gran énfasis a su amor por su tierra natal y son despiadados con sus enemigos. Su reputación de aislacionismo está bien ganada y prefieren mantenerse entre los suyos, aunque existen excepciones a este estereotipo. Los elfos de sangre son una raza de supervivientes resilientes, y sus figuras más destacadas se erigen como símbolos de coraje, tenacidad y fuerza para seguir luchando, sin importar qué enemigos se interpongan en su camino.

<div class='footnote'>RAZAS | ELFO DE SANGRE</div>
<img src='https://www.gmbinder.com/images/yEfh2ws.jpg' style='position:absolute; top:0px; right:0px; width:850px' />

<img src='https://warcraft.wiki.gg/images/d/d9/Icon_of_Blood.png' style='position:absolute; top:10px; right:400px; width:350px' />

<img src='https://www.gmbinder.com/images/bNHsRrG.png' style='position:absolute; top:100px; right:0px; width:800px; transform:rotate(180deg)' />
<img src='https://www.gmbinder.com/images/YsQdgdF.png' style='position:absolute; top:0px; right:-50px; width:500px; transform:scalex(-1)' />

\pagebreakNum

### Hermosos y Gráciles
Los elfos de sangre son físicamente similares a los elfos nobles, con la principal diferencia en sus ojos resplandecientes de color esmeralda, en contraste con el brillo azul de los elfos nobles. Tienen complexión delgada, miden alrededor de 6 pies y pesan en promedio 150 libras. Poseen orejas largas y puntiagudas, pómulos altos y, generalmente, se consideran humanos altamente atractivos. Sus tonos de piel son claros, y el cabello suele ser rubio o castaño claro, llevándolo largo tanto hombres como mujeres. La capacidad de los hombres para dejarse barba es limitada, con pocas barbas de más de una pulgada.

### Afiliación
Los elfos de sangre son en su mayoría miembros de la Horda. La raza élfica se divide entre aquellos que se identifican como elfos nobles y los que se consideran sin'dorei, quienes han jurado lealtad a la Horda para honrar a sus caídos.

Aunque no sienten un odio particular hacia la Alianza en general, las atrocidades cometidas contra ellos por humanos xenófobos han generado una profunda desconfianza hacia la Alianza y sus líderes humanos.

***Elfos de Sangre.*** Estos elfos han jurado lealtad a la Horda, convencidos por la antigua General Forestal Sylvanas Brisaveloz, quien habló en su nombre ante los líderes de la causa.

***Elfos Nobles.*** Estos elfos nunca han jurado lealtad a ninguna facción y, aunque han trabajado junto a la Alianza en el pasado, nunca confiaron lo suficiente en ella como para abandonar su aislamiento y unirse a su causa. Los elfos nobles no sienten amor por la Horda y ven a los elfos de sangre como traidores, manchados por la magia vil.

### Nombres de Elfos de Sangre
La mayoría de los elfos de sangre sobrevivientes de la Tercera Guerra han optado por conservar sus nombres de elfos nobles, y continúan otorgando estos nombres a sus hijos. Las familias orgullosas mantienen sus apellidos, que a menudo reflejan una conexión con el sol. Los nombres de familia de los elfos de sangre suelen ser más agresivos que los de los elfos nobles.
<div style='margin-top:-18px;'></div>

<br>**Nombres Masculinos:** Mariel, Athaniar, Anador, Tharama, Viridiel, Malanior, Eraeth, Ulorath, Yehru, Kithadre  
**Nombres Femeninos:** Anarial, Freja, Driana, Coria, Alanassori, Melanion, Azshara, Curlih, Setori, Amorly  
**Apellidos:** Coldtrail, Nightfeast, Darkgift, Glowvein, Warmblood, Dawntrick, Solarmind, Phoenixdreamer  

\columnbreak  

### Rasgos de los Elfos de Sangre

&nbsp;&nbsp;&nbsp;&nbsp;***Incremento de Caracteristica.*** Destreza +2, y Inteligencia +1.

***Edad.*** Los elfos de sangre alcanzan la adultez física al mismo ritmo que los humanos, pero no se les considera adultos hasta los 60 años. Pueden vivir cientos de años fácilmente y, gracias al poder de la Fuente del Sol, muchos han vivido miles de años, ya que este poder extiende sus vidas indefinidamente.

***Alineamiento.*** Los elfos de sangre viven en una sociedad donde los rangos y títulos son muy importantes, y existen estrictas leyes que deben seguir, lo que los inclina hacia alineamientos legales. Sus deseos personales varían, lo que resulta en individuos tanto de alineamiento bueno como maligno.

***Tamano.*** Los elfos de sangre miden entre 5 y 6 pies de altura y pesan entre 125 y 175 libras. Tu tamaño es Mediano. Para determinar tu altura y peso de forma aleatoria, usa el modificador de tamaño:  
<div style="margin-top: -18px; font-family: ScalySans, sans-serif">

<br>&nbsp;&nbsp;&nbsp; ***Modificador de Tamaño:*** 2d10  
&nbsp;&nbsp;&nbsp;***Altura:*** 4 pies + 9 pulgadas + Mod. tamaño (pulgadas)  
&nbsp;&nbsp;&nbsp;***Peso en Libras:*** 100 + (2d4 x Mod. tamaño)  
</div>

<div style='margin-top:-3px;'></div>

&nbsp;&nbsp;&nbsp; ***Velocidad.*** 30 pies.

***Vision en la Oscuridad.*** Puedes ver en luz tenue en un radio de 60 pies como si fuera luz brillante, y en oscuridad como si fuera luz tenue. En la oscuridad, solo puedes distinguir tonos de gris, sin distinguir colores.

***Conocimiento Arcano.*** Competencia con Arcano y puedes lanzar *detectar magia*, usando Inteligencia como tu habilidad de conjuración. Una vez que lanzas detectar magia, no puedes hacerlo de nuevo hasta un descanso corto o largo.

***Sentidos Agudos.*** Competencia en Percepción.

***Reversion de Conjuros.*** Cuando fallas una tirada de salvación contra un conjuro o efecto similar, puedes repetir la tirada y debes usar el nuevo resultado. No puedes usar esta característica de nuevo hasta que termines un descanso corto o largo.

***Legado Thalassiano.*** Ganas una de las siguientes características a tu elección:  
<div style='margin-top:-5px;'></div>

- Conoces un truco de tu elección de la lista de conjuros de mago. La Inteligencia es tu habilidad de conjuración para él.  
- Tienes competencia con la espada gemela, guja, arco corto y arco largo.  
<div style='margin-top:-5px;'></div>

&nbsp;&nbsp;&nbsp; ***Idiomas.*** Puedes hablar, leer y escribir en Común y Thalassiano. El thalassiano deriva de la lengua darnassiana de los elfos de la noche, y en muchos casos suena igual para un oído inexperto.

> ##### Crear un Elfo Noble  
> Pocos elfos nobles permanecen en Azeroth, ya que los quel'dorei se renombraron como sin'dorei, elfos de sangre, al recuperar gran parte de su hogar del Azote. Puedes crear un elfo noble usando los rasgos raciales de un elfo de sangre, ya que las dos razas son indistinguibles.

<div class='footnote' style='color:lightgrey'>RAZAS | ELFO DE SANGRE</div>

<img src='https://www.gmbinder.com/images/vDsOBWh.jpg' style='position:absolute; top:720px; right:0px; width:800px' />
<img src='https://www.gmbinder.com/images/qV5FBIk.png' style='position:absolute; top:-50px; right:-0px; width:800px; transform:scaley(-1)' />

\pagebreak

---

\columnbreak

## Goblin
*Yo no oculto lo que me enorgullece. Si el mundo fuera a partirse en dos mañana, compraría el Portal Oscuro, pondría un peaje y cobraría el último cambio de bolsillo, los anillos de sus dedos, un bocado de su comida y una obligación contractual de construirme un palacio cohete en los cielos de Nagrand. ¡Es el modo goblin! ¡Oferta y demanda! ¡Acéptalo!*
<div style="text-align:Right"> 

*— Príncipe del Comercio Jastor Gallywix* &nbsp;</div>
<div style='margin-top:-5px'></div>

Esclavos de los trols de la jungla en su isla natal, los goblins fueron obligados a extraer mineral de kaja'mita del volcánico Monte Kajaro. Este mineral tuvo un efecto inesperado: aumentó su inteligencia. Comenzaron a rebelarse en secreto, creando artefactos y brebajes alquímicos para derrocar a sus opresores y reclamar Kezan como su hogar.

Su antigua prisión se convirtió en un imperio creciente 
<span style="margin-left:20px">en las minas que habían excavado. Para su pesar, los</span>
<span style="margin-left:30px">efectos del mineral se desvanecieron, y su</span> 
<span style="margin-left:35px">inteligencia disminuyó al agotarse la kaja'mita. Su</span> 
<span style="margin-left:35px">brillantez se volvió más improvisada y caótica. La</span>
<span style="margin-left:34px">astucia y la avaricia tomaron su lugar, elevando a la</span>
<span style="margin-left:30px">raza a maestros del mercantilismo. Se amasaron</span>
<span style="margin-left:27px">grandes fortunas, y la isla se convirtió en un centro</span>
<span style="margin-left:24px">para comerciantes goblin.</span>
<span style="margin-left:15px"></span>

### Tecnología
El amor de los goblins por la mecánica a menudo los pone en competencia directa con los gnomos, quienes comparten un gusto por los dispositivos. Aunque esta competencia suele ser amistosa, los goblins destacan con invenciones legendarias como desbrozadoras mecánicas y dirigibles que cruzan terrenos difíciles. Su ingenio tecnológico ha sido clave para su ascenso, tanto como su astucia comercial.

A pesar de los fallos y explosiones frecuentes, la tecnología goblin rivaliza con la de los enanos. Mientras otras razas construyen para la posteridad, los goblins buscan que sus inventos sean lo suficientemente fiables para cumplir su propósito inmediato, permitiéndoles crear más y en menos tiempo.

### Comerciantes Natos
Los goblins han adoptado el rol de comerciantes, y es raro viajar sin encontrar una tienda goblin. Sus negocios están en todo Azeroth, incluso en lugares remotos o peligrosos. Venderán cualquier cosa a cualquiera, por precios algo inflados.

Si bien muchas tiendas son independientes, un número creciente declara ser propiedad de la Compañía Comercial Ventura, una organización controlada por goblins desde una lejana ciudad de calles doradas.

La tenacidad de los goblins para el comercio y su diversidad de ofertas los hace famosos en todo Azeroth.

<div class='footnote'>RAZAS | GOBLIN</div>

<img src='https://www.gmbinder.com/images/grtcWyc.jpg' style='position:absolute; top:0px; right:300px; width:1195px' />
<img src='https://i.pinimg.com/originals/50/9f/07/509f072bb05dacf7b667394d688c1f7f.jpg' style='position:absolute; top:0px; right:-500px; width:1340px' />

<img src='https://warcraft.wiki.gg/images/8/8e/Goblin-Icon.png' style='position:absolute; top:0px; right:470px; width:350px' />

<img src='https://www.gmbinder.com/images/Npi5n8k.png' style='position:absolute; top:0px; right:0px; width:900px' />
<img src='https://www.gmbinder.com/images/tdgTze8.png' style='position:absolute; top:340px; right:325px; width:500px; transform:scalex(-1)' />

\pagebreakNum

### Pequeños pero matones
Los goblins son de baja estatura y delgados, con un promedio de menos de 4 pies de altura y un peso promedio de 50 libras; las goblins suelen ser un poco más altas que los machos. Su piel verde recuerda a la de los orcos, aunque puede oscurecerse al sol, adquiriendo tonos verdes más ricos y apagados. Además de sus grandes orejas, las narices de los goblins continúan creciendo a lo largo de sus vidas, llegando a medir varias pulgadas.

### Afiliación
Los goblins son miembros de la Horda. Aunque han trabajado y comerciado con miembros de la Horda desde hace tiempo, no fue hasta el Cataclismo que el Cártel Pantoque juró lealtad a la creciente Horda. A pesar de que muchos goblins se han alineado con la Horda, algunos siguen manteniendo su neutralidad, comerciando con ambas facciones siempre que haya compradores.

Pocos goblins muestran abiertamente odio o desconfianza hacia otros miembros de la Horda, disfrutando de la seguridad y las posiciones lucrativas que han ganado dentro de sus filas.

#### Goblins y Gnomos
Los goblins sienten una rivalidad con los gnomos, viéndolos no como enemigos, sino como competidores. Esto los lleva a enfrentamientos amistosos y, a veces, brutales para demostrar cuál de las dos razas es superior.

### Nombres
Los goblins reciben su nombre al nacer y lo conservan hasta la muerte. Sin embargo, algunos adoptan apodos que reflejan su personalidad, colocándolos antes de su nombre de nacimiento, como "Modiste Altanera".

Los goblins tienen familias numerosas con apellidos que suelen reflejar los logros de algún antepasado. Si un goblin supera en logros a sus predecesores, puede reemplazar su apellido por uno nuevo que represente sus propias hazañas.
<div style='margin-top:-18px;'></div>

<br>**Nombres Masculinos:** Nees, Ford, Joxdeld, Zatval, Fivinkle, Bova, Geevegbix, Rolaz, Ixa, Saz, Menzen, Gilmaxle
<br>**Nombres Femeninos:** Trutte, Meez, Kleqe, Suva, Tweedo, Cynmee, Twinkle, Klasi, Teexma, Ninzi
<br>**Apellidos:** Brokenblast, Shifttale, Saltsnipe, Deadknob, Nifttweak, Cogbeast, Slyfire, Manbelt

### Rasgos de los Goblins

&nbsp;&nbsp;&nbsp;&nbsp;***Incremento de Caracteristica.*** Inteligencia +1 y Carisma +2.

***Edad.*** Los goblins maduran un poco más lento que los humanos y alcanzan la adultez a principios de sus 20 años. La mayoría muere antes de llegar al siglo, pero pueden vivir hasta la mitad de su segundo siglo.

***Alineamiento.*** La mayoría de los goblins tienden al caos neutral, mostrando poco sentido moral y disfrutando el presente sin pensar mucho en las consecuencias.

***Tamaño.*** Los goblins miden entre 3 y 4 pies y pesan entre 40 y 80 libras. Tu tamaño es Pequeño. Para determinar tu altura y peso de manera aleatoria, usa el siguiente modificador:
<div style="margin-top: -18px; font-family: ScalySans, sans-serif">

<br>&nbsp;&nbsp;&nbsp; ***Modificador de Tamaño:*** 2d4
<br>&nbsp;&nbsp;&nbsp; ***Altura:*** 2 pies + 12 pulgadas + Mod. tamaño (pulgadas)
<br>&nbsp;&nbsp;&nbsp; ***Peso en Libras:*** 40 + (1 x Mod. tamaño)
</div>

&nbsp;&nbsp;&nbsp; ***Velocidad.*** 25 pies.

***Mejores Tratos.*** Siempre que hagas un chequeo de Carisma (Persuasión) relacionado con regatear, se considera que tienes competencia en la habilidad Persuasión y puedes añadir el doble de tu bonificación de competencia.

***Esquivar*** Puedes darte ventaja en una tirada de salvación de Destreza contra un efecto visible, como una trampa o un hechizo. Debes decidir usar esta característica antes de realizar la tirada. No puedes volver a usarla hasta completar un descanso corto o largo.

***Ingenieria Goblin.*** Tienes competencia con herramientas de artesano (herramientas de manitas). Puedes gastar 1 hora y 25 piezas de oro en materiales para construir un dispositivo pequeño (CA 5, 1 PV). El dispositivo deja de funcionar después de 24 horas (a menos que pases 1 hora para mantenerlo) o tras activarse. Al descomponerse, puedes recuperar 5 piezas de oro en materiales.

Cuando creas este dispositivo, elige uno de los siguientes hechizos: *manos ardientes, catapulta, temblor de tierra, caída de pluma, grasa, salto,* o *onda atronadora*. Usas tu Inteligencia como habilidad para lanzar hechizos.

***Familiaridad Mecanica.*** Competencia en armas de fuego y herramientas de artesano (herramientas de armero).

***Idiomas.*** Puedes hablar, leer y escribir en Común, Goblin y un idioma adicional de tu elección. Los goblins comercian con cualquier raza que compre, aprendiendo los idiomas de aquellos con quienes comercian.

<div class='footnote' style='color:lightgrey'>RAZAS | GOBLIN</div>

<img src='https://www.gmbinder.com/images/VaHU2Gc.jpg' style='position:absolute; top:570px; right:-150px; width:600px' />
<img src='https://www.gmbinder.com/images/wvTUmvu.png' style='position:absolute; top:90px; right:0px; width:800px' />
<img src='https://www.gmbinder.com/images/E8GrMME.png' style='position:absolute; top:0px; right:0px; width:900px' />

\pagebreakNum

<style> .phb#p33:after { display:none; } </style>
<div class='cover-header'> <div style='margin-top:50px;'></div> Razas Aliadas </div>
<img src='https://www.gmbinder.com/images/kkjaoG4.jpg' style='position:absolute; top:0px; right:-65px; width:900px' />

\pagebreak

<div style='margin-top:147px;'></div>

## Nocheterna

Una barrera impenetrable fue colocada alrededor <br>de Suramar, protegiendo a los Altonato de la Gran Fractura. Este escudo los mantuvo aislados del <br>resto de Azeroth durante miles de años, obligándolos <br>a depender del Pozo de la Noche para su poder mágico. Con el tiempo, evolucionaron y se llamaron *shal'dorei* o Nocheterna.

Cuando los suministros de Suramar se agotaron, los *shal'dorei* comenzaron a usar la energía del Pozo de la Noche como sustento, evitando una muerte prematura, pero esto los hizo dependientes de la magia del Pozo. El crimen se castigaba con el exilio, y al desconectarse del Pozo de la Noche, los exiliados se desmoronaban y eventualmente se convertían en *marchitos*, sin mente y esperando la muerte.

Diez mil años después, los Nocheterna bajaron su barrera y se rindieron a la Legión Ardiente por órdenes de su líder, la Gran Magistrix Elisande. Aunque muchos Nocheterna no estuvieron de acuerdo, ninguno se atrevió a desafiar a las fuerzas demoníacas. Gracias a la resistencia Nocheterna y la ayuda de la Alianza y la Horda, la Gran Magistrix y sus aliados demoníacos fueron rechazados al Vacío Abisal.

### Nacidos en la Oscuridad
Encerrados en su capital, Suramar, los Nocheterna tienen un físico similar al de sus parientes elfos de la noche: altos, esbeltos y musculosos. Sin embargo, el cielo oscuro de su ciudad ha dado a su piel un tono azul o púrpura oscuro, en contraste con los colores vibrantes de los elfos de la noche. Los shal'dorei continúan practicando la magia arcana, lo que da a sus ojos un resplandor azul o púrpura, en lugar del brillo dorado de los elfos de la noche.

Orgullosos de su dominio de las artes arcanas, los Nocheterna lucen tatuajes resplandecientes de energía arcana. Aunque no tienen un impacto conocido en sus habilidades, estos tatuajes simbolizan su conexión y comprensión del arte arcano.

### Civilización de los Altonato
Los *shal'dorei* tienen un aire de superioridad que a menudo se percibe como pomposo. Se deleitan en su civilización mágica incomparable, pero al no haber tenido contacto con las razas actuales de Azeroth hasta que la rebelión llevó una fuerza invasora para liberar Suramar, muchos todavía consideran al mundo exterior y sus razas como indignos, incultos y muy por debajo de los estándares de la civilización Nocheterna.

Estos eran algunos de los aspectos menos admirables de la antigua civilización élfica, y los *shal'dorei* los mantienen como si nada hubiera cambiado y todavía fueran el centro del mundo.

\columnbreak

<div style='margin-top:640px;'></div>

### Afiliación
Los Nocheterna han estado aislados del mundo durante miles de años en su ciudad capital, Suramar. Derivados de los elfos de la noche Altonato, algunos han mostrado interés en reunirse con sus antiguos parientes tras la caída de la barrera. Sin embargo, también sienten afinidad con los elfos de sangre, debido a su adicción similar a una fuente de poder.

Algunos Nocheterna han optado por mantener una postura neutral, ya que la Tercera Invasión de la Legión Ardiente los ha llevado a buscar nuevos aliados.

&nbsp; ***Alianza.*** Pocos Nocheterna han decidido jurar lealtad a la Alianza, considerando que la organización es demasiado cerrada para una raza que ha pasado los últimos diez mil años en aislamiento. La cautela y desconfianza expresadas por sus parientes elfos de la noche también han alejado a muchos de la Alianza.

&nbsp; ***Horda.*** Muchos Nocheterna han encontrado terreno común con los elfos de sangre de la Horda, quienes han expresado una relación similar con los elfos de la noche y comparten una adicción similar a una fuente de poder. Los elfos de sangre han demostrado ser grandes aliados de los Nocheterna y han abierto la puerta para que se unan a la Horda.

<div class='footnote'>RAZAS | NOCHETERNA</div>
<img src='https://www.gmbinder.com/images/Lru8laS.jpg' style='position:absolute; top:0px; right:-100px; width:1050px; transform:scalex(-1)' />
<img src='https://www.gmbinder.com/images/eHNEyoC.png' style='position:absolute; top:0px; right:0px; width:900px' />
<img src='https://www.gmbinder.com/images/3JjxENt.png' style='position:absolute; top:-40px; right:-30px; width:500px' />

\pagebreakNum

### Nombres Nocheterna
Los nombres de los Nocheterna son similares a los de los elfos de la noche y a menudo contienen significados ocultos. Pocos *shal'dorei* mantienen apellidos, los cuales suelen derivar de las hazañas de sus antepasados. Rara vez adoptan un nuevo apellido, ya que valoran profundamente el legado familiar.

**Masculinos:** 

**Femeninos:** 

**Apellidos:** 

### Rasgos Nocheterna
&nbsp;&nbsp;&nbsp;&nbsp;***Incremento de Caracteristica.*** Destreza +1 y Inteligencia +2.

***Edad.*** Los Nocheterna alcanzan la madurez física al ritmo de los humanos, pero su concepto de la adultez va más allá del desarrollo físico. Normalmente reclaman su adultez y un nombre adulto alrededor de los 100 años, y pueden vivir miles de años.

***Alineamiento.*** El orden y la estructura son fundamentales en la sociedad Nocheterna; para ellos, la reputación y el estatus son cruciales, y la moralidad suele ser vista a través de esta perspectiva. Debido a esto, la mayoría de los Nocheterna tienden hacia alineamientos legales.

***Tamano.*** Los Nocheterna miden entre 7 y 8 pies de altura y pesan entre 180 y 220 libras. Tu tamaño es Mediano. Para determinar tu altura y peso aleatoriamente, lanza el modificador de tamaño:
<div style="margin-top: -18px; font-family: ScalySans, sans-serif">

<br>&nbsp;&nbsp;&nbsp; ***Modificador de Tamaño:*** 2d8
<br>&nbsp;&nbsp;&nbsp; ***Altura:*** 6 pies + 8 pulgadas + Mod tamaño (pulgadas)
<br>&nbsp;&nbsp;&nbsp; ***Peso en Libras:*** 130 + (2d6 x Mod tamaño)
</div>

<div style='margin-top:-3px;'></div>

&nbsp;&nbsp;&nbsp; ***Velocidad.*** 30 pies.

***Vision en la Oscuridad Superior.*** Puedes ver en luz tenue hasta 120 pies como si fuera luz brillante y en la oscuridad como si fuera luz tenue. Tu herencia Nocheterna hace que todo lo que veas en la oscuridad sea en tonos de violeta.

***Sensibilidad a la Luz Solar.*** Tienes desventaja en las tiradas de ataque y en los chequeos de Sabiduría (Percepción) que dependan de la vista cuando tú, tu objetivo o lo que intentas percibir esté bajo luz solar directa.

***Conocimiento Arcano.*** Competente con Arcano.

***Sentidos Agudos.*** Competente con Percepción.

***Proteccion Mental.*** Ventaja en todas las tiradas de salvación de Inteligencia, Sabiduría y Carisma contra magia.

***Magia Nocheterna.*** Conoces el truco *mano de mago*. Al alcanzar el 3er nivel, puedes lanzar el conjuro *detectar magia* una vez al día. Al alcanzar el 5º nivel, también puedes lanzar el conjuro *desenfoque* una vez al día. La Inteligencia es tu habilidad de lanzamiento de conjuros para estos conjuros.

***Idiomas.*** Puedes hablar, leer y escribir Común y Shalassiano. El Shalassiano, al igual que el Thalassiano, proviene del idioma Darnassiano. Su dialecto ha sido refinado a lo largo de los siglos, lo que lo hace casi imposible de leer o escribir para aquellos que no pertenecen a los Nocheterna.

<div class='footnote'>RAZAS | NOCHETERNA</div>
<img src='https://www.gmbinder.com/images/UWr8pFE.jpg' style='position:absolute; top:0px; right:-400px; width:1910px' />
<img src='https://www.gmbinder.com/images/E8GrMME.png' style='position:absolute; top:0px; right:0px; width:900px' />

\pagebreakNum

<div style='margin-top:400px;'></div>

## Pandaren
Los pandaren han sido un misterio para <br> las demás razas de Azeroth durante<br>  mucho tiempo, su historia se <br> remonta a miles de años, antes del<br>  ascenso de los kaldorei. Habitantes de una tierra maravillosa y fértil, los pandaren fueron esclavos de los antiguos mogu forjados por los titanes. Con tenacidad, diplomacia y una forma única de combate desarmado, llevaron a cabo una exitosa revolución que derrocó a los mogu y estableció los cimientos del imperio pandaren que prosperó durante miles de años.

Cuando tuvo lugar la Gran Fractura, Pandaria quedó envuelta en una niebla mágica que duró miles de años. Con el paso del tiempo, la niebla que rodeaba Pandaria se desvaneció, atrayendo la atención de ambas facciones, que deseaban reclamar esta tierra "inexplorada" y descubrir lo que había en su superficie.

### Armonía en Todas las Cosas
Los pandaren son lentos para enojarse y prefieren buscar soluciones mesuradas a los problemas. En Pandaria, las emociones negativas se aprovechan y toman forma física para causar estragos en la isla. Los pandaren enfatizan y cultivan una vida tranquila de armonía interior y enfoque. Los conflictos, por amargos que sean, se olvidan rápidamente con una bebida fría una vez que el asunto en cuestión se ha resuelto.

\columnbreak

<div style='margin-top:658px;'></div>

### Una Raza Espiritual
Los pandaren tienen una profunda creencia en la conexión entre el mundo material y el espiritual. Son una sociedad que reacciona en lugar de actuar primero. Muchos afirman ser como el agua que fluye alrededor de una roca: nunca la empuja fuera de su camino, sino que simplemente la rodea. Este es el núcleo de su sociedad, una forma simple de vivir día a día. Si se enfocan en una tarea y fallan, creen que tomaron el enfoque incorrecto e intentan de nuevo.

### Cubiertos de Pelaje
Los pandaren, cubiertos de un denso pelaje colorido, son osos humanoides masivos que miden entre poco menos de 6 pies y casi 7 pies. Son naturalmente robustos, y su peso varía entre 250 y 400 libras. Los machos suelen ser más altos y pesados que las hembras.

Su coloración varía de marrón oscuro a amarillo dorado, pero todos tienen marcas blancas en el rostro y, a menudo, en las patas o el torso. Aunque no tienen cabello, muchos estilizan el pelaje en la parte superior de su cabeza para asemejarlo al cabello.

<div class='footnote'>RAZAS | PANDAREN</div>
<img src='https://www.gmbinder.com/images/6XAsG6F.jpg' style='position:absolute; top:0px; right:0px; width:800px' />
<img src='https://www.gmbinder.com/images/kDzvP48.png' style='position:absolute; top:-170px; right:0px; width:1000px' />
<img src='https://www.gmbinder.com/images/6aiPMLT.png' style='position:absolute; top:-13px; right:-180px; width:750px; transform:scalex(-1); z-index:10' />

\pagebreakNum

### Afiliación
Los pandaren son una raza independiente que ha estado oculta del mundo desde los días de la Guerra de los Ancestros. Su tierra natal, Pandaria, se encuentra lejos de las fronteras de la Horda y la Alianza, y la mayoría de los pandaren han adoptado una postura neutral con respecto a las facciones y sus causas. Sin embargo, algunos entre los pandaren han jurado lealtad a una de las facciones, alineándose con la que comparta sus ideales y creencias.

El mundo y los habitantes de Azeroth son nuevos para los pandaren, y pocos entre esta raza armoniosa muestran desconfianza, ira o odio hacia otras razas, sin importar su facción.

***Alianza.*** Estos pandaren son conocidos comúnmente como pandaren *tushui*, aquellos cuyas enseñanzas fomentan vivir una vida honorable a través de la meditación, el entrenamiento riguroso y la convicción moral. Los pandaren que sostienen los principios de los *Tushui* se sienten atraídos por la Alianza y su filosofía similar.

***Horda.*** Estos pandaren son conocidos como pandaren *huojin*, quienes creen firmemente que la injusticia debe ser respondida de manera rápida y decisiva, aunque esta respuesta debe ser flexible y calculada según la situación. Para los *Huojin*, el fin siempre justificará los medios. Los pandaren que abrazan los principios de los *Huojin* se sienten atraídos por la practicidad de la Horda.

### Nombres
Las prácticas de nombramiento pandaren son similares a las de los humanos. Cada pandaren recibe un nombre al nacer y lleva el apellido familiar de sus padres. Algunos pandaren son conocidos por adoptar un nuevo apellido que refleje sus propios logros en la vida, aunque esta práctica no es común.
<div style='margin-top:-18px;'></div>

<br> **Nombres Masculinos:** Fan Su, Tan Delan, Tian Fu, Fan-Su, Zi Ling, Gao, Bai, Wei He, Xun Ming, Dong-Gun
<br> **Nombres Femeninos:** Sujin, Zemin, Seul-Gi, Heng Lei, Sun-Mi, Zheng, Yan, Wei Zhelan, Xuefeng, Li, Liuxian
<br> **Apellidos:** Caskriver, Drumfriends, Wisespear, Keenwalker, Calmbrow, Mellowcoil, Ironshadow, Wildfur

\columnbreak

### Rasgos de los Pandaren
&nbsp;&nbsp;&nbsp;&nbsp;***Incremento de Caracteristica.*** Constitución +1 y Sabiduría +2.

***Edad.*** Los pandaren envejecen al mismo ritmo que los humanos, alcanzando la adultez en su adolescencia tardía y, en general, no suelen vivir más de un siglo.

***Alineamiento.*** Los pandaren son una raza pacífica y sociable que, en su mayoría, tiende a cuidar de los suyos, haciendo que la mayoría de los pandaren tengan una alineación neutral o buena. Los pandaren malvados son raros y encontrar uno suele ser el resultado de magia oscura que influye en su mente.

***Tamano.*** Los pandaren miden entre 5 y 7 pies de altura y pesan entre 250 y 400 libras. Tu tamaño es Mediano. Para determinar tu altura y peso aleatoriamente, lanza el modificador de tamaño:
<div style="margin-top: -18px; font-family: ScalySans, sans-serif">

<br>&nbsp;&nbsp;&nbsp; ***Modificador de Tamaño:*** 2d10
<br>&nbsp;&nbsp;&nbsp; ***Altura:*** 5 pies + 2 pulgadas + Mod tamaño (pulgadas)
<br>&nbsp;&nbsp;&nbsp; ***Peso en Libras:*** 150 + (2d6 x Mod tamaño)
</div>

<div style='margin-top:-3px;'></div>

&nbsp;&nbsp;&nbsp; ***Velocidad.*** 30 pies.

***Gourmet.*** Obtienes competencia con herramientas de artesano (utensilios de cocina) y herramientas de artesano (suministros de cervecería).

***Paz Interior.*** Tienes ventaja en tiradas de salvación contra ser encantado o asustado.

***Experto Marcial.*** Luchando para proteger su hogar y familia, tus ataques desarmados infligen 1d4 + tu modificador de Fuerza como daño contundente en un golpe. Además, obtienes un bono de +1 a tu Clase de Armadura. Para usar este bono, no debes llevar armadura mediana o pesada ni usar un escudo.

***Palma Temblorosa.*** Eres capaz de atacar puntos focales en un objetivo. Como acción adicional, puedes hacer un ataque desarmado especial. Si el ataque impacta, causa su daño normal y el objetivo debe superar una tirada de salvación de Constitución (CD 8 + tu modificador de Sabiduría + tu bonificador por competencia). Si falla, queda aturdido hasta el final de tu próximo turno.

Después de usar tu palma temblorosa, no puedes volver a usarla hasta que termines un descanso corto o largo.

***Idiomas.*** Puedes hablar, leer y escribir Común y Pandaren. El Pandaren es el idioma de Pandaria, descendiente del lenguaje de los mogu que fue impuesto a los habitantes de Pandaria por el imperio mogu. Es un idioma extraño y desconocido para el resto de Azeroth, con múltiples palabras que significan una misma cosa.

<div class='footnote'>RAZAS | PANDAREN</div>

<img src='https://www.gmbinder.com/images/SvYw20C.jpg' style='position:absolute; top:700px; right:0px; width:800px' />
<img src='https://www.gmbinder.com/images/L60ii4e.png' style='position:absolute; top:23px; right:0px; width:850px; transform:scalex(-1)' />

\pagebreak

<div style='margin-top:131px;'></div>

## Elfos del Vacío
Infundidos por el propio vacío, los Ren'dorei--hijos del vacío--son un grupo de elfos de sangre exiliados de su tierra natal, Quel'Thalas. Rechazados por sus enseñanzas debido al magíster elfo Umbric, estos elfos han abrazado sus nuevos poderes, aunque la agitación interna que les ha causado bien puede acompañarlos a lo largo de sus vidas mientras luchan por mantener el control.

### Moldeados por el Vacío
Los elfos del vacío, aunque comparten sangre con los otros elfos, se distinguen por su piel pálida o vibrante con tonos azulados, ojos y cabello impregnados de sombras en tonos oscuros de azul y púrpura. A veces, sus poderes oscuros se manifiestan en el cabello, con puntas que brillan con energía del vacío.

Muchos que intentaron dominar los poderes del vacío cayeron en la locura, pero la antigua general forestal Alleria Brisaveloz fue la primera en lograrlo, ahora guiando a sus hermanos elfos junto al magíster Umbric. Los elfos del vacío buscan utilizar estos poderes para defender la Alianza y Azeroth, demostrando su valía ante aquellos que dudan de ellos.

### Exiliados de su Hogar
Originalmente, los elfos del vacío eran discípulos y seguidores de Umbric, un magíster de la corte de Lunargenta, quien creía que el vacío era clave para la supervivencia de Quel'Thalas tras su destrucción a manos de la Plaga.

Sin embargo, otros magísteres no compartían esta visión, especialmente el Gran Magíster, quien finalmente desterró a los elfos por temor a que el vacío representara un gran peligro para el reino y para la Fuente del Sol.

Ahora, fortalecidos por sus nuevos poderes, los elfos del vacío han jurado hacer valer su lugar en el mundo bajo el liderazgo conjunto del magíster Umbric y Alleria Brisaveloz.

### Etéreos, Amigos y Enemigos
Seres de energía, los etéreos son criaturas extradimensionales que han viajado grandes distancias a través del Gran Oscuro. Comúnmente compuestos de energías arcanas, un grupo de etéreos tocados por el vacío transformó a los Ren'dorei en lo que son hoy. Alleria Brisaveloz, co-líder de Umbric, debe gran parte de su poder a las enseñanzas de un etéreo llamado Locus-Walker.

Gracias a las maquinaciones de los etéreos del vacío, que buscaban convertir a Umbric y sus seguidores en verdaderos seres del vacío, y la intervención oportuna de Alleria, estos antiguos habitantes de Quel'Thalas se convirtieron en algo más. Ahora, Locus-Walker y otros etéreos cuyos objetivos coinciden con los Ren'dorei deambulan por la Grieta de Telogrus, enseñando y guiando a todos los Hijos de Quel'Thalas en el camino del Vacío.

\columnbreak

<div style='margin-top:790px;'></div>

### Afiliación
Los elfos del vacío son una subraza independiente de los elfos de sangre que fueron exiliados de Quel'Thalas por su trato con el vacío. Estos elfos eligen abrazar o intentar olvidar su condición de parias, pues siempre serán malvenidos en la tierra que dejaron atrás.

***Alianza.*** Estos elfos han aprendido a controlar el vacío bajo la guía de la general forestal Alleria Brisaveloz y le han jurado servicio. Con ella como líder, prometieron su lealtad a la Alianza tras la derrota de la Legión Ardiente en Argus.

***Horda.*** No existen elfos del vacío en la Horda, ya que todos aquellos que aprendieron a controlar el vacío juraron seguir a la general forestal Alleria Brisaveloz y se unieron a la Alianza.

<div class='footnote'>RAZAS | ELFOS DEL VACIO</div>
<img src='https://www.gmbinder.com/images/JLhq6RD.jpg' style='position:absolute; top:-100px; right:0px; width:800px' />
<img src='https://www.gmbinder.com/images/H47MOpD.png' style='position:absolute; top:0px; right:0px; width:900px' />
<img src='https://www.gmbinder.com/images/kDzvP48.png' style='position:absolute; top:0px; right:0px; width:1000px' />
<img src='https://www.gmbinder.com/images/hTLvvHS.png' style='position:absolute; top:100px; right:-200px; width:800px' />

\pagebreakNum

> ##### Surgimiento de los Elfos del Vacío
> Los Ren'dorei son un grupo específico de elfos del vacío que siguieron las enseñanzas del magíster Umbric, aunque no es el primer elfo que ha experimentado con el vacío. Habla con tu DM si deseas jugar como un elfo del vacío antes de la derrota de la Legión Ardiente en Argus.

### Nombres
Siguen las mismas convenciones que los elfos de sangre. Sin embargo, tras su exilio de Quel'Thalas, algunos han optado por cambiar su apellido para reflejar sus nuevos poderes y su conexión con el vacío.

<div style='margin-top:-18px;'></div>

<br>**Apellidos:** Coldtrail, Nightfeast, Voidworn, Morncloud, Duskblood, Darkvein, Gloomwalker, Voidheart

### Rasgos de los Elfos del Vacío

&nbsp;&nbsp;&nbsp;&nbsp;***Incremento de Caracteristica.*** Destreza +2 y Inteligencia o Carisma +1.

***Edad.*** Alcanzan la adultez física al ritmo de los humanos, pero no se consideran adultos hasta cumplir 60 años y pueden vivir cientos de años. Muchos han vivido miles de años gracias al poder de la Fuente del Sol, que prolonga sus vidas indefinidamente.

***Alineamiento.*** Aunque el caos y la imprevisibilidad son prominentes en muchos elfos del vacío, han mantenido una alineación legal similar a la de los elfos de sangre. Aquellos que sucumben al vacío a menudo se vuelven caóticos.

***Tamano.*** Miden entre 5 y 6 pies de altura y pesan entre 125 y 175 libras. Tu tamaño es Mediano. Para determinar tu altura y peso aleatoriamente, lanza el modificador de tamaño:
<div style="margin-top: -18px; font-family: ScalySans, sans-serif">

<br>&nbsp;&nbsp;&nbsp; ***Modificador de Tamaño:*** 2d10
<br>&nbsp;&nbsp;&nbsp; ***Altura:*** 4 pies + 9 pulgadas + mod de tamaño (pulgadas)
<br>&nbsp;&nbsp;&nbsp; ***Peso en Libras:*** 100 + (2d4 x tu modificador de tamaño)
</div>

<div style='margin-top:-3px;'></div>

&nbsp;&nbsp;&nbsp; ***Velocidad.*** 30 pies.

***Vision en la Oscuridad.*** Puedes ver en luz tenue hasta 60 pies como si fuera luz brillante y en oscuridad como si fuera luz tenue, aunque solo distingues tonos de gris y no colores.

***Sentidos Agudos.*** Competente en Percepción.

***Frio de la Noche.*** Resistencia al daño necrótico.

***Grieta Espacial.*** Como acción adicional, abres una grieta en el espacio y el tiempo, teletransportándote mágicamente hasta 30 pies a un espacio desocupado que puedas ver. Una vez que uses este rasgo, no puedes volver a hacerlo hasta un descanso corto o largo.

***Legado Thalassiano.*** Ganas una de las siguientes características a tu elección:
<div style='margin-top:-5px;'></div>

- Conoces un truco de tu elección de la lista de conjuros de mago. La Inteligencia es tu habilidad para lanzar conjuros.
- Tienes competencia con la hoja gemela, la guja de guerra, el arco corto y el arco largo.
<div style='margin-top:-5px;'></div>

&nbsp;&nbsp;&nbsp; ***Idiomas.*** Puedes hablar, leer y escribir Común y Thalassiano. El Thalassiano deriva del idioma darnassiano de los elfos de la noche, y en muchos casos suena igual para un oído inexperto.

\columnbreak

<div style='margin-top:500px;'></div>

## Vulpera
Los vulpera han vivido en Vol'dun como comerciantes y mercaderes libres por generaciones. Durante mucho tiempo, han sido oprimidos por los sethrak Desleales, quienes esclavizaron a innumerables vulpera, obligándolos a trabajar y luchar para ellos. Los vulpera son en su mayoría pacíficos y nunca lograron detener a los sethrak. Al menos una caravana intentó resistir, pero fue derrotada.

### Carroñeros y Sobrevivientes
Los vulpera son una raza astuta e inteligente de carroñeros nómadas, expertos en aprovechar lo que encuentran para prosperar. Son habilidosos en resolver problemas, sin importar su magnitud, y aunque de pequeña estatura, son feroces e ingeniosos en combate, derrotando a quienes los subestiman. Tienen asentamientos en madrigueras, pero sus caravanas viajan de escondite en escondite, recolectando suministros, comerciando y compartiendo información. Su carroñeo a menudo incluye saquear artefactos y tesoros de antiguas ruinas para venderlos al mejor postor.

### Recolectores Ingeniosos
Al vivir en Vol'dun, los vulpera no pueden permitirse desperdiciar recursos. Con el tiempo, han aprendido a tomar cualquier cosa que parezca mínimamente útil y ser creativos con lo que tienen, reconociendo el valor dondequiera que se esconda en el desierto. Cuando les advirtieron que el oro del Puerto de Zem'lan estaba maldito, Norah respondió: "Una pequeña maldición nunca ha alejado a un vulpera de un tesoro valioso".

<div class='footnote'>RAZAS | ELFOS DEL VACIO</div>
<img src='https://www.gmbinder.com/images/qX8jehA.png' style='position:absolute; top:-40px; right:-120px; width:550px; transform:scalex(-1)' />

\pagebreakNum

### Afiliación
Los vulpera son una raza independiente originaria del cálido desierto de Vol'dun. Aunque algunos entre ellos continúan llevando un estilo de vida nómada y libre, muchos vulpera han optado por unirse a las grandes facciones de Azeroth y han mostrado interés en explorar el mundo más allá del cálido clima de Vol'dun.

***Alianza.*** No existen vulpera dentro de la Alianza. Aunque la raza no siente odio hacia sus miembros, muchos vulpera han seguido al líder de la caravana, Kiro, y han jurado lealtad a la Horda.

***Horda.*** Estos vulpera han vivido la dureza de Vol'dun y de sus habitantes. Agradecidos con la Horda por su ayuda, siguieron al líder de la caravana, Kiro, para unirse a la Horda, devolver el favor y explorar el mundo más allá de sus tierras.

### Nombres
Los vulpera reciben su nombre poco después de nacer, dado por la caravana nómada con la que viajan, en lugar de por sus padres. Para ellos, la caravana es la familia, y todas las voces tienen igual peso. Sus nombres son cortos, de dos o tres sílabas como máximo. No tienen apellidos, y pocos eligen usarlos.

<div style='margin-top:-18px;'></div>

<br>**Nombres Masculinos:** Deelni, Jaamre, Jenoh, Keerin, Kenzou, Kiro, Nemru, Rikati, Shalku, Unjun
<br>**Nombres Femeninos:** Erri, Eudora, Jena, Kova, Meerah, Nisha, Norah, Rehea, Saiva, Venah

### Rasgos Vulpera

&nbsp;&nbsp;&nbsp;&nbsp;***Incremento de Caracteristica.*** Destreza +2 y Inteligencia +1.

***Edad.*** Maduran más rápido que los humanos, alcanzando la adultez física a los 5 años. Sin embargo, no se les considera adultos hasta que están listos para asumir las responsabilidades de su clan y caravana. Envejecen rápidamente y rara vez viven más de 75 años.

\columnbreak

&nbsp;&nbsp;&nbsp;&nbsp;***Alineamiento.*** La mayoría tienden a ser neutrales puros, se centran en cuidar de los suyos y velar por su bienestar. Sin embargo, su afecto por otros puede ser interpretado como actos de bondad, incluso si no provienen del corazón.

***Tamano.*** Los vulpera miden entre 3 y 4 pies de altura y pesan alrededor de 50 libras. Tu tamaño es Pequeño. Para determinar tu altura y peso aleatoriamente, lanza el modificador de tamaño:
<div style="margin-top: -18px; font-family: ScalySans, sans-serif">

<br>&nbsp;&nbsp;&nbsp; ***Modificador de Tamaño:*** 2d4
<br>&nbsp;&nbsp;&nbsp; ***Altura:*** 2 pies + 8 pulgadas + mod tamaño (pulgadas)
<br>&nbsp;&nbsp;&nbsp; ***Peso en Libras:*** 35 + (1 x mod tamaño)
</div>

<div style='margin-top:-3px;'></div>

&nbsp;&nbsp;&nbsp; ***Velocidad.*** 30 pies.

***Nacido del Desierto.*** Estás naturalmente adaptado a climas cálidos, tal como se describe en el capítulo 5 de la *Guía del Dungeon Master*.

***Furia del Pequeño.*** Cuando infliges daño a una criatura con un ataque o conjuro y la criatura es de un tamaño mayor que el tuyo, puedes causar daño adicional igual a tu nivel. Una vez que uses este rasgo, no podrás hacerlo de nuevo hasta un descanso corto o largo.

***Oido Agudo.*** Ventaja en los chequeos de Sabiduría (Percepción) que dependan del oído.

***Conocimiento Nómada.*** Obtienes competencia en una de las siguientes habilidades a tu elección: Manejo de Animales, Naturaleza, Sigilo o Supervivencia.

***Olfato para el Peligro.*** Puedes realizar la acción de Desengancharse o Esquivar como acción adicional durante tu primer turno de cada combate. Si te sorprenden al comienzo del combate y no estás incapacitado, aún puedes realizar la acción de Esquivar en tu primer turno.

***Explorador.*** Siempre que hagas un chequeo de Sabiduría (Supervivencia) relacionado con la navegación, se te considera competente en la habilidad de Supervivencia y agregas el doble de tu bonificador por competencia al chequeo, en lugar de tu bonificador normal.

***Idiomas.*** Puedes hablar, leer y escribir Común y dos idiomas adicionales de tu elección. Los vulpera son una raza nómada que adquiere los idiomas de quienes les rodean.

<div class='footnote'>RAZAS | VULPERA</div>

<img src='https://www.gmbinder.com/images/ji0HTvu.jpg' style='position:absolute; top:620px; right:0px; width:1000px' />
<img src='https://www.gmbinder.com/images/wvTUmvu.png' style='position:absolute; top:35px; right:0px; width:1000px' />

\pagebreak

<style> .phb#p41:after { display:none; } </style>
<img src='https://www.gmbinder.com/images/N3q1qJX.jpg' style='position:absolute; top:0px; right:-25px; width:850px' />

\pagebreak

# Capítulo 2: Clases
Los héroes son personas extraordinarias, impulsadas por una sed de emoción hacia una vida que pocos se atreverían a llevar. Tu clase define lo que tu personaje puede hacer y va más allá de una simple profesión: es su llamado. Moldea tu perspectiva del mundo, cómo interactúas con él y tu relación con los demás y las fuerzas del multiverso.

Por ejemplo, un guerrero ve el mundo de manera pragmática, mientras que un sacerdote se considera parte de un plan mayor. Un guerrero tiene contactos en compañías mercenarias, mientras que un sacerdote se relaciona con sanadores y paladines.

Tu clase te otorga características especiales, como el dominio de armas y armaduras de un guerrero o los conjuros de un mago. Al principio, tendrás dos o tres características, pero a medida que avanzas en nivel obtendrás más y mejorarás las existentes. Cada entrada de clase incluye una tabla con los beneficios de cada nivel y una explicación detallada.

A veces, los héroes avanzan en más de una clase. Un pícaro puede jurar el voto de un paladín o un guerrero bárbaro descubrir una habilidad mágica latente mientras sigue desarrollándose como guerrero.

<div style='margin-top:0px;'></div>

<div class='classTable wide'>

##### Clases
|Clase|&nbsp;&nbsp;&nbsp;|Descripción|Dado Golpe|&nbsp;|Caracteristica Principal|&nbsp;|Competencia<br>Salvaciones&nbsp;&nbsp;&nbsp;|&nbsp;|Competencia <br>Armaduras y Armas|
|:---------------------|-|:----------|:-----------|-|:-------------------|-|:-----------------|-|:-------------------------------|
|Caballero de la Muerte||Un caballero no-muerto, experto con armas y fuerzas de la muerte.              |d10||Fuerza y Carisma      ||Constitución y Carisma ||Todas las armaduras, armas simples y marciales|
|Cazador de Demonios   ||Un luchador forjado por el vil, enseñado en el odio a los demonios.           | d8||Destreza             ||Destreza y Carisma    ||Armadura ligera, armas simples y marciales, gujas|
|Druida                ||Un guardián de la naturaleza, con poderes de Elune y capaz de transformarse en animales.| d8||Sabiduría y Constitución||Inteligencia y Sabiduría   ||Armadura ligera, armas simples|
|Cazador               ||Un experto rastreador, con conocimientos sobre la naturaleza y sus criaturas.|d10||Destreza y Sabiduría   ||Fuerza y Destreza    ||Armadura ligera y media, armas simples y marciales, armas de fuego|
|Mago                  ||Un estudioso de la magia, capaz de invocar y moldear la energía arcana.      | d6||Inteligencia         ||Inteligencia y Sabiduría   ||Armas simples|
|Monje                 ||Un artista marcial que aprovecha el poder<br> del cuerpo para lograr la perfección espiritual.| d8||Destreza y Sabiduría   ||Fuerza y Destreza    ||Armadura ligera, armas simples, espadas cortas|
|Paladín               ||Un guerrero sagrado que usa la luz para ayudar a sus aliados y derrotar a sus enemigos.|d10||Fuerza y Carisma      ||Sabiduría y Carisma       ||Todas las armaduras, escudos, armas simples y marciales|
|Sacerdote             ||Un servidor fiel de grandes poderes, manipulando la luz y la oscuridad en su nombre.| d6||Carisma             ||Sabiduría y Carisma       ||Armas simples|
|Pícaro                ||Un maestro del sigilo y el engaño, que usa la astucia para superar obstáculos.| d8||Destreza            ||Destreza e Inteligencia||Armadura ligera, armas simples, ballestas de mano, espadas largas, estoques, espadas cortas|
|Chamán                ||Un dominador de elementos, que los invoca a su favor y los somete a su voluntad.| d8||Sabiduría           ||Fuerza y Sabiduría       ||Armadura ligera y media, armas simples|
|Brujo                 ||Un maestro de la magia vil y del vacío, que obtiene su poder a través de un grimorio.|d8||Inteligencia y Sabiduría||Inteligencia y Sabiduría||Armas simples, espadas largas, estoques, cimitarras, espadas cortas||
|Guerrero              ||Un combatiente excepcional, diestro en el uso de diversas armas y armaduras.|d10||Fuerza             ||Fuerza y Constitución ||Todas las armaduras, escudos, armas simples y marciales|
</div>

<div class='footnote'>PARTE 2 | CLASES</div>

\pagebreakNum

## Caballero de la Muerte
*Un héroe... eso es lo que una vez fuiste. Te enfrentaste a la sombra y compraste otro amanecer para este mundo al costo de tu vida. Pero el mal al que luchaste no es tan fácilmente erradicado, la victoria que reclamaste no es tan fácil de mantener. El espectro de la muerte se cierne sobre este mundo nuevamente, ha encontrado nuevos campeones para traer su reinado final. Caballeros de la oscuridad, esta es la hora de tu renacimiento oscuro...*

<div style="text-align:Right"> 

*— Un caballero de la Espada de Ébano* &nbsp;</div>

Un humano con armadura pesada empuña una gran espada con ambas manos; runas destellan a lo largo del filo, dejando un rastro de humo negro tras sus golpes.

Un orco, rodeado de kobolds, hunde su hacha en el suelo, marchitando la tierra a su alrededor y aterrando a los kobolds, que huyen despavoridos.

Una elfa de sangre avanza sola por el campo de batalla, su armadura cubierta de escarcha y la tierra congelándose bajo sus pies.

Los caballeros de la muerte sirven a los poderes de la muerte, empuñando armas infundidas con runas de poder. Son guerreros despiadados resucitados por las val'kyr, con los poderes de los caballeros de la muerte del Bastión de Ébano. Aunque parecen muertos, están muy vivos.

### Desterrados de por Vida
Aunque estos caballeros de la muerte no son no-muertos como sus predecesores, llevan gran parte de la esencia de los antiguos caballeros. Desde la distancia, parecen muertos vivientes, con miradas blancas y vacías que observan el mundo. Aunque están vivos y no carecen de emociones, muchos los rechazan por lo que han llegado a ser. Los caballeros de la muerte son portadores de muerte y destrucción, un hecho difícil de olvidar.

Esto ha llevado a muchos caballeros de la muerte a seguir un camino solitario; muchos se mantienen en las afueras de pueblos y ciudades, o esconden bien su apariencia antes de entrar.

### Renacimiento Funesto
Ser resucitado como caballero de la muerte no es una tarea sencilla y es aún más complicada por la cicatriz que deja en el recién resucitado. Obtener los poderes de los caballeros de la muerte debilita el alma durante un tiempo considerable, un precio que debe ser pagado. No solo debilita al caballero de la muerte, sino que algunas cicatrices son visibles para todos; su resurrección ha llenado su cuerpo de energía necrótica que siempre estará presente, un rasgo que se manifiesta en sus ojos, que siempre serán dos luces blancas en sus cuencas.

### Guerreros Tenaces
Los caballeros de la muerte son guerreros excepcionales y, en muchos aspectos, similares a los paladines, siendo diestros con varias armas y capaces de luchar con cualquier armadura, complementando su combate con el uso de la magia. Empuñan sus armas rúnicas potenciadas y la magia de sombras, lo que les permite dominar a la mayoría de los enemigos que se atrevan a enfrentarse a ellos, haciéndolos combatientes temibles en cualquier situación.

\columnbreak

<div style='margin-top:670px;'></div>

### Creando un Caballero de la Muerte
Al crear tu caballero de la muerte, piensa en cómo llegaste a este camino. La mayoría fueron levantados bajo el control del Rey Exánime, y luego rompieron sus lazos de esclavitud. Considera cómo este cambio afecta tu visión del mundo: ¿te sientes distante o interesado en lo que ocurre a tu alrededor? Piensa también en la relación con tu familia: ¿aún existen? ¿te aceptarían tal como eres o te rechazarían? Tal vez antes fuiste una figura importante, un líder o un soldado en un ejército.

> ##### Regla Adicional: A Caballo Pálido
> Las criaturas invocadas por un caballero de la muerte con *encontrar corcel* y *encontrar corcel superior* son no-muertas, en lugar de uno de los tipos de criatura listados en esos conjuros.

<div class='footnote'>CLASES | CABALLERO DE LA MUERTE</div>
<img src='https://www.gmbinder.com/images/V3AJiIc.jpg' style='position:absolute; top:0px; right:-600px; width:1300px' />
<img src='https://www.gmbinder.com/images/Npi5n8k.png' style='position:absolute; top:0px; right:-50px; width:870px; transform:scalex(-1)' />
<img src='https://www.gmbinder.com/images/4RyvlFl.png' style='position:absolute; top:0px; right:-170px; width:650px' />

\pagebreakNum

<div class='classTable wide'>

##### El Caballero de la Muerte
|Nivel|Bonus de<br>Competencia|Rasgos|Conjuros<br>Conocidos|&nbsp;|1|&nbsp;|2|&nbsp;|3|&nbsp;|4|&nbsp;|5 <div style="position: absolute; top:85px; right:62px; width:200px; height:25px">—Espacios de Conjuro por Nivel—</div>|
|:---:|:--:|:--------------------------------------------|:-:|-|:-:|-|:-:|-|:-:|-|:-:|-|:-:|
| 1  | +2  | Renacer Oscuro, Armas Rúnicas, Poder Rúnico |—||—||—||—||—||—|
| 2  | +2  | Estilo de Combate, Lanzamiento de Conjuros  |2||2||—||—||—||—|
| 3  | +2  | Constitución No-Muerta, Presencia Maligna   |3||3||—||—||—||—|
| 4  | +2  | Mejora de Característica                    |3||3||—||—||—||—|
| 5  | +3  | Ataque Extra                                |4||4||2||—||—||—|
| 6  | +3  | Forja de Runas                              |4||4||2||—||—||—|
| 7  | +3  | Rasgo de Presencia                          |5||4||3||—||—||—|
| 8  | +3  | Mejora de Característica                    |5||4||3||—||—||—|
| 9  | +4  | —                                           |6||4||3||2||—||—|
| 10 | +4  | Voluntad de la Tumba                        |6||4||3||2||—||—|
| 11 | +4  | Rasgo de Presencia                          |7||4||3||3||—||—|
| 12 | +4  | Mejora de Característica                    |7||4||3||3||—||—|
| 13 | +5  | —                                           |8||4||3||3||1||—|
| 14 | +5  | Sin Muerte                                  |8||4||3||3||1||—|
| 15 | +5  | Rasgo de Presencia                          |9||4||3||3||2||—|
| 16 | +5  | Mejora de Característica                    |9||4||3||3||2||—|
| 17 | +6  | —                                           |10||4||3||3||3||1|
| 18 | +6  | Forja de Runas Superior                     |10||4||3||3||3||1|
| 19 | +6  | Mejora de Característica                    |11||4||3||3||3||2|
| 20 | +6  | Rasgo de Presencia                          |11||4||3||3||3||2|
</div>

&nbsp;&nbsp;&nbsp; Reflexiona sobre cómo llegaste a este destino: ¿cómo moriste y qué historias guarda esa muerte? Considera los efectos de haber sido resucitado como no-muerto, los cambios de personalidad que eso trajo y los intereses que pudiste haber perdido de tu vida anterior. Convertirse en caballero de la muerte es una reencarnación; estás atrapado en tu propio cuerpo, pero con una nueva visión del mundo.

#### Creación Rápida
Haz que caracteristica principal sea Fuerza, seguida de Carisma.

#### Multiclase
&nbsp;&nbsp;&nbsp;&nbsp;***Caracteristica Minima.*** Debes tener al menos 13 de Fuerza y Carisma para coger un nivel, o para coger un nivel en otra clase si eres caballero de la muerte.

***Competencias Adquiridas.*** Armadura ligera, armadura media, armas simples y armas marciales.

***Espacios de Conjuro.*** Suma la mitad de tus niveles (redondeado hacia arriba) en la clase de caballero de la muerte a los niveles apropiados de otras clases para determinar tus espacios de conjuro disponibles.

\columnbreak

## Rasgos de Clase
#### Puntos de Golpe
___
- **Dado de Golpe:** 1d10 por nivel de caballero de la muerte
- **PG al nivel 1:** 10 + Mod. Constitución
- **PG por nivel:** 1d10 (o 6) + Mod. Constitución por nivel de caballero de la muerte

#### Competencias
___
- **Armaduras:** Todas las armaduras
- **Armas:** Armas simples, armas marciales
- **Herramientas:** Ninguna
- **Tiradas de Salvación:** Constitución, Carisma
- **Habilidades:** Elige dos entre Atletismo, Engaño, Intimidación, Investigación, Percepción y Sigilo

#### Equipo
Comienzas con el siguiente equipo, además del equipo concedido por tu trasfondo:
- *(a)* un arma marcial o *(b)* dos espadas cortas
- *(a)* cinco jabalinas o *(b)* cualquier arma simple
- *(a)* cota de escamas o *(b)* cota de malla
- *(a)* un paquete de aventurero de mazmorras o *(b)* un paquete de explorador
- Un amuleto de tu vida pasada

<div class='footnote'>CLASES | CABALLERO DE LA MUERTE</div>


\pagebreakNum

### Renacer Oscuro
Como caballero de la muerte, caminas entre el mundo de los vivos y los muertos, existiendo en ambos y en ninguno.

 - Eres considerado tanto un humanoide como un no-muerto, lo cual te permite ser afectado por cualquier cosa que afecte a esos tipos de criatura. Por ejemplo, como no-muerto, puedes ser detectado por el Sentido Divino de un paladín, pero como humanoide, puedes ser sanado por su Imposición de Manos.
 - No necesitas dormir. En su lugar, entras en un estado semi-consciente, alimentando tu hambre eterna recordando el sufrimiento causado. Después de 4 horas en este estado, obtienes los mismos beneficios que un humano tras 8 horas de sueño.
 - Ventaja en las tiradas de salvación contra cualquier efecto que afecte exclusivamente a los no-muertos, como el conjuro *Encadenar no muertos* de un sacerdote.

### Armas Rúnicas
Sabes inscribir runas en armas, dotándolas de poder y uniéndolas a ti. Realizas un ritual de 1 hora para inscribir las runas, que puede completarse durante un descanso corto. Las armas deben estar a tu alcance durante todo el ritual. Solo puedes tener un arma de dos manos unida o dos armas de una mano. Vincular nuevas armas rompe inmediatamente el vínculo con las anteriores.

No puedes ser desarmado de tus armas rúnicas a menos que estés incapacitado. Si están en el mismo plano de existencia que tú, puedes invocarlas como acción adicional, teletransportándolas a tus manos. Si tienes dos armas rúnicas de una mano, al usar un rasgo de caballero de la muerte que se refiera a tu arma rúnica, puedes elegir cuál usar (pero no ambas).

### Poder Rúnico
Energías necróticas recorren tu cuerpo que se representa con una reserva de d6 que se recarga tras un descanso largo. El número de dados en esta reserva es igual a 1 + nivel de caballero de la muerte. Nunca puedes gastar más dados rúnicos que tu Mod Carisma (mínimo 1).

#### Espiral de la Muerte
Gasta dados de Poder Rúnico como acción y elige una criatura visible dentro de 120 pies. Si es no-muerta, recupera puntos de golpe iguales al resultado de los dados. Si no es no-muerta, realizas conjuro a distancia usando Mod Carisma; si impactas, infliges daño necrótico igual al doble del resultado de los dados gastados.

#### Golpe Rúnico
Cuando impactas a una criatura con un ataque cuerpo a cuerpo, puedes gastar dados de tu reserva de Poder Rúnico para infligir daño necrótico adicional al objetivo igual al resultado de los dados gastados, además del daño del arma.

### Estilo de Combate
A partir del nivel 2, adoptas un estilo particular de combate como tu especialidad. Elige una de las siguientes opciones. No puedes elegir una opción de Estilo de Combate más de una vez, incluso si más adelante puedes elegir otra.

\columnbreak

> ##### Caballeros de la Muerte Renegados
> Las bendiciones oscuras del caballero de la muerte se manifiestan de manera diferente para los Renegados que ya son no-muertos. Los caballeros de la muerte Renegados no necesitan dormir en absoluto y pueden pasar sus descansos realizando actividades ligeras. Además, son inmunes a cualquier efecto que convierta o afecte exclusivamente a los no-muertos, como el conjuro *Encadenar no muertos* de un sacerdote.

#### Defensa
Mientras lleves armadura, obtienes un bono de +1 a la CA.

#### Duelos
Cuando empuñas un arma cuerpo a cuerpo en una mano y no tienes otras armas, obtienes un bono de +2 a las tiradas de daño con esa arma.

#### Gran Lucha con Armas
Cuando obtienes un 1 o 2 en un dado de daño con un ataque cuerpo a cuerpo usando un arma empuñada con ambas manos, puedes volver a tirar y usar el nuevo resultado, incluso si es un 1 o un 2. El arma debe tener la propiedad de dos manos o ser versátil.

#### Guerrero Profano
Aprendes dos trucos de tu elección de la lista de conjuros de brujo. Se consideran conjuros de caballero de la muerte para ti, y tu habilidad para lanzarlos es Carisma. Siempre que subas de nivel en esta clase, puedes reemplazar uno de estos trucos con otro de la lista de conjuros de brujo.

#### Combate con Dos Armas
Cuando portas dos armas, puedes agregar tu modificador de habilidad al daño del segundo ataque.

### Lanzamiento de Conjuros
A partir del nivel 2, el poder otorgado por las fuerzas de la muerte te da habilidad con hechizos. Consulta el capítulo 10 del Manual del Jugador para las reglas generales de lanzamiento de conjuros y el capítulo 6 de este libro para la lista de conjuros de caballero de la muerte.

#### Espacios de Conjuro
La tabla de caballero de la muerte muestra cuántos espacios de conjuro tienes para lanzar tus conjuros de caballero de la muerte de 1er a 5º nivel. Para lanzar uno de estos conjuros, debes gastar un espacio del nivel del conjuro o superior. Recuperas todos los espacios de conjuro gastados cuando terminas un descanso largo. Muchos caballeros de la muerte manifiestan sus espacios de conjuro visiblemente como runas de poder en sus armas rúnicas.

Por ejemplo, si conoces el conjuro de 1er nivel *cuchillo de hielo* y tienes un espacio de conjuro de 1er nivel y uno de 2º nivel disponible, puedes lanzar *cuchillo de hielo* usando cualquiera de esos espacios.

<div class='footnote'>CLASES | CABALLERO DE LA MUERTE</div>

\pagebreakNum

#### Conjuros Conocidos de 1er Nivel y Superiores
Conoces dos conjuros de 1er nivel de tu elección de la lista de conjuros de caballero de la muerte.

La columna de Conjuros Conocidos de la tabla de caballero de la muerte muestra cuándo aprendes más conjuros de caballero de la muerte de tu elección. Cada uno de estos conjuros debe ser de un nivel para el que tengas espacios de conjuro. Por ejemplo, cuando llegas al nivel 5 en esta clase, puedes aprender un nuevo conjuro de 1er o 2º nivel.

Además, cuando subes de nivel en esta clase, puedes elegir uno de los conjuros de caballero de la muerte que conoces y reemplazarlo por otro de la lista de conjuros de caballero de la muerte, que también debe ser de un nivel para el que tengas espacios de conjuro.

### Habilidad para Lanzar Conjuros
El Carisma es tu habilidad para lanzar conjuros de caballero de la muerte, así que usas tu Carisma siempre que un conjuro se refiera a tu habilidad para lanzar conjuros. Además, utilizas tu modificador de Carisma para establecer la CD de la tirada de salvación de un conjuro de caballero de la muerte que lances y para realizar una tirada de ataque con un conjuro.

<div style="text-align: Center">

**CD de salvación de conjuros** =<br> 8 + Bonus competencia + Mod. Carisma

**Modificador de ataque con conjuros** =<br> Bonus competencia + Mod. Carisma
</div>

#### Foco para Lanzar Conjuros
Puedes usar un arma rúnica como foco para lanzar tus conjuros de caballero de la muerte.
<div style='margin-top:-3px;'></div>

### Constitución No-Muerta
A partir del nivel 3, tu naturaleza no-muerta te hace inmune a las enfermedades y a la condición de envenenado, además de ser resistente al daño por veneno.
<div style='margin-top:-3px;'></div>

### Presencia Maligna
Al alcanzar el nivel 3, te comprometes por completo con un aspecto de la muerte: Sangre, Escarcha o Profano. Tu elección te otorga rasgos en el nivel 3 y nuevamente en los niveles 7, 11, 15 y 20.
<div style='margin-top:-3px;'></div>

#### Conjuros de Presencia
Cada presencia tiene una lista de conjuros asociados. Aprendes estos conjuros a los niveles especificados en la descripción de la presencia. Los conjuros de presencia no cuentan contra el número de conjuros de caballero de la muerte que puedes conocer.

Si obtienes un conjuro de presencia que no aparece en la lista de conjuros de caballero de la muerte, sigue siendo un conjuro de caballero de la muerte para ti.
<div style='margin-top:-5px;'></div>

### Mejora de Característica
Cuando alcanzas el nivel 4, y nuevamente en los niveles 8, 12, 16 y 19, puedes aumentar una puntuación de característica de tu elección en 2, o puedes aumentar dos puntuaciones de característica de tu elección en 1. Como es habitual, no puedes aumentar una puntuación de característica por encima de 20 usando esta característica.

\columnbreak

<div style='margin-top:-3px;'></div>

### Ataque Extra
A partir del nivel 5, puedes atacar dos veces, en lugar de una, siempre que realices la acción de Ataque en tu turno.
<div style='margin-top:-3px;'></div>

### Forja de Runas
A partir del nivel 6, aprendes a inscribir encantamientos en tus armas rúnicas. Siempre que termines un descanso largo, puedes inscribir una de las siguientes runas en tus armas. Obtienes los beneficios de la runa mientras empuñas las armas rúnicas. Solo puedes tener una runa activa a la vez.
<div style='margin-top:-3px;'></div>

#### Runa de Glaciar de Ceniza
Cuando golpeas a una criatura con un ataque de arma, la criatura tiene desventaja en cualquier tirada de salvación que haga contra tus rasgos y conjuros de caballero de la muerte hasta el final de tu próximo turno.
<div style='margin-top:-5px;'></div>

#### Runa del Cruzado Caído
Cuando logras un golpe crítico o reduces a una criatura a 0 puntos de golpe con un ataque de arma, puedes curarte de inmediato con *espiral de la muerte* como parte de la misma acción y recuperar puntos de golpe igual al doble del resultado obtenido en los dados de poder rúnico gastados.

#### Runa del Juramento del Liche
Obtienes un bono de +2 a tu modificador de ataque con conjuros.

#### Runa de Rompeconjuros
Obtienes resistencia al daño infligido por conjuros.

#### Runa de Rompeespadas
Obtienes un bono de +2 a tu Clase de Armadura.

#### Runa de Caminante Espectral
Tu velocidad de movimiento aumenta en 10 pies y obtienes un bono a tu iniciativa igual a tu modificador de Carisma (mínimo de +1).

### Voluntad de la Tumba
A partir del nivel 10, no puedes ser encantado ni asustado mientras estés consciente.

### Sin Muerte
A partir del nivel 14, no necesitas comer, beber ni respirar. Además, envejeces a un ritmo más lento. Por cada 10 años que pasan, tu cuerpo solo envejece 1 año, y eres inmune al envejecimiento mágico.

### Forja de Runas Superior
Al alcanzar el nivel 18, puedes inscribir dos runas diferentes en tus armas rúnicas al mismo tiempo (según lo descrito en tu rasgo de Forja de Runas), y ambas pueden ser cambiadas cuando completes un descanso largo.

<div class='footnote'>CLASES | CABALLERO DE LA MUERTE</div>

\pagebreakNum

## Presencia Maligna
Los caballeros de la muerte son los guerreros de los condenados, creados para profanar la tierra que pisan. Los caminos que recorren los caballeros de la muerte pueden clasificarse en tres presencias. Elige una de ellas para tu caballero de la muerte.

### Presencia de Sangre
En su estado de no-muerte, algunos caballeros de la muerte encuentran una afinidad especial por la sangre y los huesos de los vivos. Se abren paso a través de sus enemigos, sosteniéndose con ataques mortales y sangrientos, mientras utilizan los restos destrozados de los muertos para reforzar sus propias defensas. Estos caballeros empapados en sangre retuercen las reglas de la mortalidad para controlar las líneas de frente del campo de batalla.

#### Conjuros de Presencia
Obtienes conjuros de presencia a los niveles de caballero de la muerte listados.

##### Conjuros de Presencia de Sangre
| Nivel de CdM | Conjuros                            |
|:----:|:----------------------------------|
| 3º   | *mandato, ✦ agarre de la muerte*            |
| 5º   | *✦ hervir sangre, inmovilizar persona*      |
| 9º   | *✦ asfixiar, transferencia de vida*         |
| 13º  | *localizar criatura, ✦ cambio de vacío*     |
| 17º  | *caparazón antivida, ✦ cadena de la muerte* |
<div style='margin-top:-5px;'></div>

*✦ Los nuevos conjuros se encuentran en el capítulo 6 más adelante en este libro* 

<div class='footnote'>CLASES | CABALLERO DE LA MUERTE</div>

#### Comando Oscuro
Cuando eliges esta presencia en el nivel 3, obtienes la capacidad de influir en otras criaturas. Cuando infliges daño a una criatura mediante tu rasgo de Poder Rúnico, esa criatura tiene desventaja en las tiradas de ataque contra objetivos que no sean tú hasta el final de tu próximo turno.

#### Escudo de Sangre
A partir del nivel 3, aprendes a tejer tu magia vil en una barrera protectora. Cuando lanzas un conjuro de caballero de la muerte de 1er nivel o superior, puedes usar la esencia oscura del conjuro para crear un escudo de sangre sobre ti que dura hasta que termines un descanso largo. El escudo tiene puntos de golpe iguales al doble de tu nivel de caballero de la muerte + tu modificador de Carisma. Siempre que recibas daño, el escudo lo absorbe primero. Si el daño reduce el escudo a 0 puntos de golpe, recibes cualquier daño restante.

Mientras el escudo de sangre tenga 0 puntos de golpe, no puede absorber daño, pero su magia permanece. Siempre que lances un conjuro de caballero de la muerte de 1er nivel o superior, el escudo recupera puntos de golpe iguales al doble del nivel del conjuro.

Una vez que crees un escudo de sangre, no puedes volver a crearlo hasta que termines un descanso largo.

\columnbreak

#### Tormenta de Huesos
A partir del nivel 7, puedes usar tu acción para invocar un torbellino de huesos afilados a tu alrededor. La tormenta tiene un radio de 20 pies y está centrada en ti. Se mueve contigo y dura 1 minuto o hasta que estés incapacitado o mueras. Cuando una criatura entra en el área por primera vez en un turno o comienza su turno allí, debe realizar una tirada de salvación de Destreza. Si falla, la criatura recibe daño perforante mágico igual a 1d6 + tu nivel de caballero de la muerte y cae derribada. Si tiene éxito, recibe la mitad del daño y no sufre otros efectos.

Una vez que uses esta característica, no puedes volver a usarla hasta que termines un descanso corto o largo.

#### Golpe al Corazón
En el nivel 11, tu poder oscuro refuerza tus ataques. Siempre que golpeas a una criatura con un ataque cuerpo a cuerpo, la criatura recibe un daño adicional de 1d8 de arma. Además, el daño infligido por tus armas rúnicas ignora resistencias.

#### Purgatorio
A partir del nivel 15, cuando seas reducido a 0 puntos de golpe y no mueras instantáneamente, puedes optar por quedar con 1 punto de golpe en su lugar y reponer los puntos de golpe de tu escudo de sangre al doble de tu nivel de caballero de la muerte.

Una vez que uses esta habilidad, no podrás volver a usarla hasta que termines un descanso largo.

#### Arma Rúnica Danza
En el nivel 20, puedes invocar una copia espectral de tu arma rúnica, que danza de manera amenazante en tu espacio. El arma rúnica danzante dura 1 minuto y es idéntica a tu arma rúnica. Una vez que uses esta característica, no puedes volver a usarla hasta que termines un descanso largo.

Al comienzo de cada uno de tus turnos, puedes comandar a tu arma rúnica danzante para que actúe de una de las siguientes maneras hasta el inicio de tu próximo turno (no se requiere acción).

***Defensivamente.*** Obtienes los beneficios de la acción de Esquivar. Además, obtienes una reacción especial que puedes usar una vez en cada turno de criatura, excepto en tu turno. Puedes usar esta reacción especial cuando una criatura que puedas ver realiza un ataque contra un objetivo que no seas tú y que esté a 10 pies de ti, imponiendo desventaja en la tirada de ataque.

&nbsp;&nbsp;&nbsp; ***Ofensivamente.*** Cuando realices la acción de Ataque en tu turno, puedes hacer un ataque adicional con el arma rúnica danzante como parte de la misma acción. Además, obtienes una reacción especial que puedes usar una vez en cada turno de criatura, excepto en tu turno. Solo puedes usar esta reacción especial para realizar un ataque de oportunidad con tu arma rúnica danzante y no puedes usarla en el mismo turno que tomas tu reacción normal.

<img src='https://www.gmbinder.com/images/0Juz7SO.png' style='position:absolute; top:870px; right:45px; width:350px; z-index:1' />

\pagebreakNum

### Presencia de Escarcha
Combinando destreza marcial con frío sobrenatural, estos guerreros condenados dejan a sus enemigos helados hasta los huesos. A diferencia de los magos que aprenden a manejar la magia de escarcha con gran eficacia, estos caballeros de la muerte nacen de ella, la escarcha atrapa sus corazones marchitos. Estos guerreros no-muertos helados empuñan espadas dobles para atacar con ferocidad y causar frío mortal a cualquiera que se les oponga.

#### Conjuros de Presencia
Obtienes conjuros de presencia a los niveles de caballero de la muerte listados.

##### Conjuros de Presencia de Escarcha
| Nivel de CdM | Conjuros                                |
|:----:|:-----------------------------------------------|
| 3º   | *armadura de agathys, ✦ toque gélido*          |
| 5º   | *✦ explosión aullante, viento protector*       |
| 9º   | *tormenta de aguanieve, caminar por el agua*   |
| 13º  | *escudo de fuego (escudo de frío), ✦ toque congelante*|
| 17º  | *cono de frío, ✦ furia del dragón de la muerte*|
<div style='margin-top:-5px;'></div>

*✦ Los nuevos conjuros se encuentran en el capítulo 6 más adelante en este libro* 

#### Golpe de Escarcha
Cuando eliges esta presencia en el nivel 3, aprendes a potenciar tus ataques con furia invernal. Cuando gastas dados de Poder Rúnico en un golpe rúnico, los dados se convierten en d8 y el golpe rúnico inflige daño por frío en lugar de daño necrótico.

#### Máquina de Matar
También a partir del nivel 3, tus ataques con armas cuerpo a cuerpo obtienen un golpe crítico con una tirada de 19 o 20. Además, puedes usar combate con dos armas incluso si las armas cuerpo a cuerpo que empuñas no son ligeras, siempre que no tengan las propiedades de pesada o dos manos.

#### Invierno Implacable
A partir del nivel 7, puedes usar tu acción para invocar una tormenta de viento cortante y aguanieve a tu alrededor. La tormenta tiene un radio de 20 pies y está centrada en ti. Se mueve contigo y dura 1 minuto o hasta que estés incapacitado o mueras. Cuando una criatura entra en el área por primera vez en un turno o comienza su turno allí, debe realizar una tirada de salvación de Constitución, recibiendo daño por frío igual a 1d6 + tu nivel de caballero de la muerte si falla, o la mitad si tiene éxito. Si falla, la velocidad de la criatura se reduce a la mitad hasta el inicio de su próximo turno.

Una vez que uses esta característica, no podrás volver a usarla hasta que termines un descanso corto o largo.

\columnbreak

#### Corazón Congelado
En el nivel 11, tus ataques con armas llevan consigo el frío de Rasganorte. Siempre que golpeas a una criatura con un ataque cuerpo a cuerpo, la criatura recibe un daño adicional de 1d8 por frío. Además, tus rasgos y conjuros de caballero de la muerte ignoran la resistencia al frío y tratan la inmunidad al daño por frío como resistencia.

#### Garras de Hielo
A partir del nivel 15, una vez en cada uno de tus turnos, cuando gastes dos o más dados rúnicos a la vez en un golpe rúnico, puedes realizar un ataque adicional con un arma cuerpo a cuerpo como parte de la misma acción de Ataque.

#### Pilar de Escarcha
En el nivel 20, eres capaz de canalizar el poder helado del mismísimo Trono Helado. Como acción, puedes convertirte mágicamente en un avatar del invierno todo consumidor, obteniendo los siguientes beneficios durante 1 minuto:

- Tienes resistencia al daño contundente, perforante y cortante, e inmunidad al daño por frío.
- Añades tu modificador de Carisma al daño de tus ataques con armas cuerpo a cuerpo (mínimo de 1).
- Cuando normalmente lanzarías uno o más dados para infligir daño por frío con un conjuro de caballero de la muerte, en su lugar, usas el número más alto posible para cada dado. Por ejemplo, en lugar de infligir 2d8 de daño por frío a una criatura, infliges 16.
<div style='margin-top:-5px;'></div>

&nbsp;&nbsp;&nbsp; Una vez que uses esta característica, no puedes volver a usarla hasta que termines un descanso largo.

<div class='footnote'>CLASES | CABALLERO DE LA MUERTE</div>

<img src='https://hearthstone.wiki.gg/images/thumb/9/9e/Harbinger_of_Winter_full.jpg/800px-Harbinger_of_Winter_full.jpg' style='position:absolute; top:480px; right:-180px; width:600px' />
<img src='https://www.gmbinder.com/images/wvTUmvu.png' style='position:absolute; top:20px; right:0px; width:800px' />
<img src='https://www.gmbinder.com/images/E8GrMME.png' style='position:absolute; top:0px; right:0px; width:900px' />

\pagebreakNum

### Presencia Profana
Algunos caballeros de la muerte aún encarnan la naturaleza corruptora de la plaga del Azote. Sin importar su lealtad o causa, permanecen como profanadores de la vida; y en ninguna parte se muestra más su crueldad que cuando son amenazados. Infligen las enfermedades más agresivas, siendo combatientes cuerpo a cuerpo despiadados, capaces de golpear con la fuerza de una legión no-muerta y desatar pestilencias que llevan a sus enemigos a la ruina.

#### Conjuros de Presencia
Obtienes conjuros de presencia a los niveles de caballero de la muerte listados.

##### Conjuros de Presencia Profana
| Nivel de CdM | Conjuros                                           |
|:----:|:-------------------------------------------------------|
| 3º   | *✦ explosión de cadáver, rayo de enfermedad*            |
| 5º   | *✦ caparazón antimagia, rayo de debilitamiento*         |
| 9º   | *✦ manto del cruzado caído, hablar con los muertos*     |
| 13º  | *marchitamiento, ✦ invocar no-muerto*                   |
| 17º  | *✦ ejército de los muertos, contagio*                   |
<div style='margin-top:-5px;'></div>

*✦ Los nuevos conjuros se encuentran en el capítulo 6 más adelante en este libro* 

> ##### Enfermedades Profanas
> &nbsp;&nbsp;&nbsp; **Plaga de Sangre.** La criatura enferma no puede recuperar puntos de golpe. Siempre que sea dañada por un ataque cuerpo a cuerpo, el atacante gana puntos de golpe temporales iguales a tu modificador de Carisma más la mitad de tu nivel de caballero de la muerte. La Plaga de Sangre se resiste con Constitución.
>
> **Putrefacción Críptica.** La criatura enferma solo puede usar una acción o una acción adicional en su turno, no ambas. Independientemente de sus habilidades o objetos mágicos, no puede realizar más de un ataque cuerpo a cuerpo o a distancia durante su turno. La Putrefacción Críptica se resiste con Sabiduría.
>
> **Fiebre de Escarcha.** La velocidad de la criatura se reduce a la mitad y no puede realizar reacciones. La Fiebre de Escarcha se resiste con Destreza.

#### Portador de Plagas
Cuando eliges esta presencia en el nivel 3, aprendes a propagar plagas y pestilencias mediante tu magia oscura o a través de un esbirro no-muerto. Elige <br> uno de los siguientes rasgos.

***Brotes.*** Cuando infliges daño con una habilidad de Poder Rúnico, puedes afligir a la criatura con una terrible plaga. Elige cuál de las enfermedades detalladas en la barra lateral "Enfermedades Profanas" infligir a tu objetivo, que surte efecto de inmediato. Al final de cada uno de los turnos de la criatura, puede realizar la tirada de salvación especificada en la descripción de la enfermedad. Si falla, recibe 1d6 de daño necrótico por cada dado de Poder Rúnico gastado originalmente y sigue sufriendo los efectos de la enfermedad. Si tiene éxito, no recibe daño y no sufre los efectos de la enfermedad hasta el final de su próximo turno. La enfermedad termina después de 1 minuto o cuando la criatura haya realizado tres tiradas de salvación exitosas contra la enfermedad.

Si un objetivo es afligido con una nueva enfermedad profana mientras ya sufre una enfermedad profana, la original termina y la nueva entra en efecto.

***Levantar a los Muertos.*** Aprendes a levantar a un humanoide muerto como un esbirro no-muerto. Puedes usar tu acción y gastar un espacio de conjuro de 1er nivel o superior para animar el cadáver de una criatura humanoide dentro de 30 pies de ti. Consulta las estadísticas de la criatura en el bloque de estadísticas de esbirro no-muerto. Cuando levantes un esbirro no-muerto, elige qué enfermedad lleva su ataque de Garra Putrefacta de la barra lateral "Enfermedades Profanas". Solo puedes tener un esbirro no-muerto, y levantar un nuevo cadáver destruye la magia que unía a tu esbirro anterior, convirtiéndolo en un cadáver en descomposición.

El esbirro no-muerto obedece tus órdenes lo mejor que pueda. En combate, comparte tu conteo de iniciativa, pero toma su turno inmediatamente después del tuyo. Puede moverse y usar su reacción por sí mismo, pero la única acción que toma en su turno es la acción de Esquivar, a menos que uses una acción adicional para ordenarle que realice una de las acciones en su bloque de estadísticas o las acciones Correr, Desengancharse o Ayudar. Si estás incapacitado o ausente, el esbirro actúa por sí solo.

Cuando gastes Dados de Golpe para recuperar puntos de golpe, tu esbirro recupera un número de puntos de golpe igual al resultado; no puede gastar sus propios Dados de Golpe. Si cae a 0 puntos de golpe, muere de inmediato, aunque sus restos pueden ser levantados nuevamente.

#### Plaga Profana
A partir del nivel 7, puedes usar tu acción para manifestar un enjambre vil de insectos que muerden a tus enemigos y debilitan su resolución. El aura tiene un radio de 20 pies y está centrada en ti. Se mueve contigo y dura 1 minuto o hasta que estés incapacitado o mueras. Cuando una criatura que no sea tu esbirro no-muerto entra en el área por primera vez en un turno o comienza su turno allí, debe realizar una tirada de salvación de Sabiduría. Si falla, la criatura recibe daño necrótico igual a 1d6 + tu nivel de caballero de la muerte y tiene desventaja en las tiradas de salvación contra veneno y enfermedades hasta el inicio de su próximo turno. Si tiene éxito, recibe la mitad del daño, pero no sufre otros efectos.

Una vez que uses esta característica, no puedes volver a usarla hasta que termines un descanso corto o largo.

<div class='footnote'>CLASES | CABALLERO DE LA MUERTE</div>

\pagebreakNum

#### Espada del Terror
En el nivel 11, la corrupción de las energías necróticas impregna tus ataques con armas. Siempre que golpeas a una criatura con un ataque cuerpo a cuerpo, la criatura recibe un daño adicional de 1d8 de daño necrótico. Además, tus rasgos y conjuros de caballero de la muerte, así como tu esbirro no-muerto, ignoran la resistencia al daño necrótico y tratan la inmunidad al daño necrótico como resistencia.

#### Señor de la Plaga
Al alcanzar el nivel 15, has logrado la maestría sobre tus poderes de pestilencia y plaga. Obtienes una de las siguientes características, dependiendo de tu elección en el nivel 3.

***Brotes.*** Cuando una criatura afligida con una de tus enfermedades profanas muere, puedes propagar la enfermedad a otra criatura que puedas ver a 30 pies de la criatura muerta, siempre que no estés incapacitado. Esto cuenta como una nueva instancia de la enfermedad para efectos de su duración y el número de tiradas de salvación necesarias para finalizarla antes de tiempo.

***Levantar a los Muertos.*** Cuando gastes dados de Poder Rúnico, también puedes añadir el mismo número de dados al daño del ataque de Garra Putrefacta de tu esbirro no-muerto hasta el final de su próximo turno. Si usas múltiples habilidades de Poder Rúnico antes de que tu esbirro ataque, solo se utiliza el bono más alto.

\columnbreak

#### Furia Profana
En el nivel 20, aprendes a incitar a una criatura no-muerta a un frenesí asesino. La mayoría de los caballeros de la muerte usan esta habilidad sobre sí mismos o sobre su esbirro no-muerto, pero puedes dirigirla a cualquier criatura no-muerta que puedas ver a 60 pies. Durante 1 minuto, la criatura frenética obtiene los siguientes beneficios:

- Tiene ventaja en las tiradas de salvación.
- Su velocidad de movimiento se duplica.
- Cuando realiza la acción de Ataque en su turno, puede realizar un ataque adicional como parte de esa acción.
<div style='margin-top:-5px;'></div>

&nbsp;&nbsp;&nbsp; Una vez que uses esta característica, no podrás volver a usarla hasta que termines un descanso largo.

<div class='footnote'>CLASES | CABALLERO DE LA MUERTE</div>
<img src='https://www.gmbinder.com/images/Ygr4Wc3.jpg' style='position:absolute; top:400px; right:-200px; width:1100px; transform:scalex(-1)' />
<img src='https://www.gmbinder.com/images/bNHsRrG.png' style='position:absolute; top:-210px; right:0px; width:840px; transform:scalex(-1)' />

\pagebreakNum
___
> ## Esbirro No-Muerto
>*No-muerto Mediano, maligno neutral*
> ___
> - **CA** 12 (armadura natural)
> - **PG** Mod. Constitución del esbirro + tu Mod. Carisma + 5 x nivel en esta clase
> - **Velocidad** 30 pies
>___
>|FUE|DES|CON|INT|SAB|CAR|
>|:---:|:---:|:---:|:---:|:---:|:---:|
>|16 (+3)|11 (+0)|14 (+2)|6 (-2)|8 (-1)|5 (-3)|
>___
> - **Tiradas de Salvación** Fue +5, Con +4, Sab +1
> - **Inmunidades al Daño** Veneno
> - **Inmunidades a Condiciones** encantado, agotamiento, asustado, envenenado
> - **Sentidos** visión en la oscuridad 60 pies, Percepción pasiva 9
> - **Idiomas** entiende los idiomas que conocía en vida pero no puede hablar
> ___
>
> ***Obligado a Servir.*** Los siguientes números aumentan en 1 cuando tu bonificador de competencia aumenta en 1: los bonificadores de las tiradas de salvación del esbirro no-muerto y los bonificadores para golpear y de daño de su ataque de garra putrefacta. <br>&nbsp;&nbsp;&nbsp; Además, cuando tu esbirro no-muerto hace una tirada de ataque, puedes usar tu modificador de ataque con conjuros para la tirada, en lugar de la del esbirro no-muerto. El daño de su garra putrefacta permanece sin cambios.
>
> ***Fortaleza No-Muerta.*** Si el daño reduce al esbirro a 0 puntos de golpe, debe tener éxito en una tirada de salvación de Constitución con una CD de 5 + el daño recibido, a menos que el daño sea radiante o un golpe crítico. Si tiene éxito, el esbirro queda con 1 punto de golpe en su lugar.
>
> ***Carga Tambaleante (1/descanso corto o largo).*** Al inicio de su turno, el esbirro puede duplicar su velocidad hasta el final de su turno. Si golpea a una criatura de tamaño Grande o menor en el mismo turno, la criatura debe tener éxito en una tirada de salvación de Fuerza contra la CD de tus conjuros o ser derribada.
>
> #### Acciones (Requiere tu Acción Adicional) <div style='margin-top:-5px;'></div>
> ###
>
> ***Garra Putrefacta.*** *Ataque de Arma Cuerpo a Cuerpo:* +5 para golpear, alcance 5 pies, un objetivo que puedas ver. *Impacto:* 5 (1d6 + 2) de daño necrótico. Si el objetivo es una criatura que no sea no-muerta, debe tener éxito en una tirada de salvación contra la CD de tus conjuros o sufrir los efectos de la enfermedad profana que porta. El objetivo puede repetir la tirada de salvación al final de cada uno de sus turnos, terminando el efecto sobre sí mismo con un éxito.

<img src='https://i.ibb.co/vwtJYyq/ghoul.png' style='position:absolute; top:0px; right:-400px; width:900px' />
<img src='https://www.gmbinder.com/images/Npi5n8k.png' style='position:absolute; top:0px; right:-75px; width:900px; transform:scalex(-1)' />

<div class='footnote'>CLASES | CABALLERO DE LA MUERTE</div>

\pagebreakNum

<div style='margin-top:300px'></div>

## Cazador de Demonios
*El enemigo vino a nuestro mundo, deseando extinguir toda vida. Mataron a nuestros seres queridos, arrasaron nuestros hogares, nuestras ciudades. No pudiste detenerlos. Entonces viniste a mí, con nada más que rabia y determinación. Te enseñé que lo que una vez te atormentó podía darte poder.*

*Ahora sabes que ningún sacrificio es demasiado grande si pone fin a la Legión Ardiente.*
<div style="text-align:Right"> 

*— Illidan Tempestira* &nbsp;</div>

Un elfo de la noche solitario, empuñando dos hojas curvas, observa el terreno mientras sus enemigos lo rodean. Salta hacia atrás sobre sus cabezas, balanceando sus espadas contra uno de ellos en pleno salto.

Una elfa de sangre corre con un par de gujas pesadas en sus manos. Libera la energía vil que lleva dentro, dejando un rastro de poder a medida que corre a una velocidad inhumana y salta sobre el enemigo más cercano.

Un humano robusto se mantiene a distancia mientras sus aliados luchan contra un demonio masivo. Con movimientos rápidos, lanza sus gujas hacia el demonio, infligiendo cortes profundos antes de que las gujas regresen a sus manos.

Estos cazadores han jurado su vida a una causa sagrada. Aunque sus motivaciones varían, los cazadores de demonios son protectores de Azeroth, ágiles y mortales contra sus enemigos. Combinan una fuerza letal con los devastadores efectos de la magia vil, con precisión extrema.
### Temidos y Reverenciados
La sociedad a menudo rechaza a los cazadores de demonios. La mayoría no comprende el sacrificio que hacen, por lo que muchos optan por convertirse en parias. Son mirados con recelo cuando caminan por los pueblos, pues la mayoría los desconfía y teme lo que son.

Aunque el mundo desconfíe de ellos, los cazadores de demonios no se preocupan por ello, ya que su misión es proteger al pueblo común contra las amenazas que buscan destruir Azeroth, especialmente los demonios. No son justos como los paladines que luchan por la Luz Sagrada, ni altruistas como algunos pícaros y guerreros. Son una fuerza destinada a combatir el mal, y aunque el pueblo común pueda rechazarlos, los combatientes experimentados aprecian su ayuda.

\columnbreak

<div style='margin-top:540px;'></div>

### Poder Otorgado a un Precio
Los cazadores de demonios no se entrenan como los guerreros; se crean. Es un proceso duro e irreversible que deja cicatrices que nunca sanarán. La mayoría de los que intentan someterse a los ritos para convertirse en cazador de demonios mueren por los horrores que ahora los habitan, o se suicidan debido a lo que han visto.

El núcleo de convertirse en cazador de demonios está en consumir el alma de un demonio en una ceremonia, uniéndola para siempre al cazador y suprimiéndola mediante inscripciones mágicas en la piel, infundidas con energía vil. El proceso se completa al quemar los ojos del cazador con una hoja mágica, vinculando para siempre el alma caótica del demonio. Otros procedimientos despojan al cazador de gran parte de lo que fue en su vida pasada, terminando la transformación.

### Creando un Cazador de Demonios
Al crear tu personaje cazador de demonios, considera por qué tu personaje decidió someterse a los mortales rituales. ¿Fue tu familia masacrada por los demonios de la Legión Ardiente? ¿Buscabas un poder mayor a través del vil y cómo controlarlo? ¿Estabas lleno de rabia y furia y deseabas darle un propósito más allá de la fuerza bruta? Tal vez pasaste por los rituales contra tu voluntad y, por un milagro, sobreviviste a los intentos del demonio de tomar el control. Piensa en los cazadores de demonios que te hicieron pasar por los rituales y realizaron los ritos en ti, en tu relación con ellos: ¿estás enfadado con ellos por lo que te hicieron? ¿satisfecho con su logro?

<div class='footnote'>CLASES | CAZADOR DE DEMONIOS</div>
<img src='https://www.gmbinder.com/images/8KgGgYA.jpg' style='position:absolute; top:0px; right:0px; width:800px' />
<img src='https://www.gmbinder.com/images/L60ii4e.png' style='position:absolute; top:-30px; right:0px; width:900px; transform:scaley(-1)' />
<img src='https://www.gmbinder.com/images/UYHVPmU.png' style='position:absolute; top:-50px; right:-50px; width:600px; transform:scalex(-1)' />

\pagebreakNum

<div class='classTable wide'>

##### El Cazador de Demonios
|Nivel|Bonus de<br>Competencia|Puntos de<br>Vil|Metamorfosis|Daño de<br>Metamorfosis|Características|
|:---:|:-:|:-:|:-:|:-:|:----|
|  1 | +2 | —  |—| —  | Defensa sin Armadura, Iniciación Illidari, <br> Visión Espectral |
|  2 | +2 |  2 |1| +2 | Vil, Metamorfosis |
|  3 | +2 |  3 |1| +2 | Marca Demoníaca |
|  4 | +2 |  4 |1| +2 | Mejora de Característica |
|  5 | +3 |  5 |1| +2 | Ataque Adicional, Hambre Instintiva |
|  6 | +3 |  6 |1| +2 | Rasgo de Marca Demoníaca |
|  7 | +3 |  7 |2| +2 | Evasión, mejora de Visión Espectral |
|  8 | +3 |  8 |2| +2 | Mejora de Característica |
|  9 | +4 |  9 |2| +3 | Un Cazador por Encima de Todo |
| 10 | +4 | 10 |2| +3 | Rasgo de Marca Demoníaca |
| 11 | +4 | 11 |2| +3 | Alas Demoníacas, Destreza Illidari |
| 12 | +4 | 12 |3| +3 | Mejora de Característica |
| 13 | +5 | 13 |3| +3 | Purificado por las Llamas |
| 14 | +5 | 14 |3| +3 | Mirada Reveladora |
| 15 | +5 | 15 |3| +3 | Resiliencia Abisal |
| 16 | +5 | 16 |4| +4 | Mejora de Característica |
| 17 | +6 | 17 |4| +4 | Rasgo de Marca Demoníaca |
| 18 | +6 | 18 |4| +4 | Cuerpo Atemporal |
| 19 | +6 | 19 |4| +4 | Mejora de Característica |
| 20 | +6 | 20 |5| +4 | Preparado |
</div>

&nbsp;&nbsp;&nbsp; Reflexiona sobre el impacto de la transformación, tanto física como mentalmente. Todos los cazadores de demonios que sobreviven al proceso desarrollan cuernos, que pueden ir desde pequeños salientes hasta cuernos masivos que se extienden por su cabeza. Algunos desarrollan escamas en partes del cuerpo, garras en las manos, o extremidades deformadas en miembros demoníacos. Ningún cazador de demonios atraviesa los ritos sin cambios, y cada uno emerge con mutaciones únicas.

#### Creación Rápida
Haz que tu puntuación más alta sea Destreza, seguida de Inteligencia.

#### Multiclase
&nbsp;&nbsp;&nbsp;&nbsp;***Caracteristica Minima.*** Debes tener al menos un 13 Destreza e Inteligencia para coger un nivel en esta clase, o para coger un nivel en otra clase si ya eres cazador de demonios.

***Competencias Adquiridas.*** Armas simples, armas marciales, gujas.

\columnbreak

## Rasgos de Clase
#### Puntos de Golpe
___
- **Dado de Golpe:** 1d8 por nivel de cazador de demonios
- **PG al Nivel 1:** 8 + Mod Constitución
- **PG por nivel:** 1d8 (o 5) + Mod Constitución por nivel de cazador de demonios

#### Competencias
___
- **Armaduras:** Armadura ligera
- **Armas:** Armas simples, armas marciales, gujas
- **Herramientas:** Ninguna
- **Tiradas de Salvación:** Destreza, Carisma
- **Habilidades:** Elige dos entre Acrobacias, Arcano, Perspicacia, Intimidación, Investigación, Percepción, Sigilo y Supervivencia

#### Equipo
Comienzas con el siguiente equipo, además del equipo concedido por tu trasfondo:
 - *(a)* dos gujas o *(b)* dos armas marciales
 - *(a)* dos dagas o *(b)* 10 dardos
 - *(a)* un paquete de aventurero de mazmorras o *(b)* un paquete de explorador
 - Armadura de cuero y un amuleto de tu vida pasada

<div class='footnote'>CLASES | CAZADOR DE DEMONIOS</div>

\pagebreakNum

### Defensa sin Armadura
A partir del nivel 1, mientras no lleves armadura ni un escudo, tu CA es 10 + Mod. Destreza + Mod. Inteligencia.

### Iniciación Illidari
Eres un iniciado Illidari, habiendo sobrevivido a las pruebas despiadadas de los Illidari y recibido un entrenamiento inaudito en otros lugares. Esto te otorga los siguientes beneficios:

 - En tu primer turno del combate, tienes ventaja en las tiradas de ataque contra criaturas que aún no hayan actuado.
 - Puedes tratar las armas cuerpo a cuerpo que no tengan la propiedad de pesada o de dos manos como si tuvieran las propiedades de ligereza y precisión, además de sus otras propiedades.
 - Cuando haces una prueba de Sabiduría (Supervivencia) relacionada con rastrear una criatura, se considera que tienes competencia en la habilidad de Supervivencia.

Además, tienes un odio profundo hacia los seres demoníacos y has sido entrenado para derrotarlos. Esto te otorga los siguientes beneficios adicionales:

 - Tienes ventaja en las pruebas de Sabiduría (Supervivencia) para rastrear a los demonios, así como en las pruebas de Inteligencia para recordar información sobre ellos.
 - Puedes hablar, leer y escribir Eredun.

### Visión Espectral
Te has cegado ritualmente, y tus cuencas oculares están imbuidas de magia, otorgándote una nueva forma de visión. Puedes ver normalmente en oscuridad, tanto normal como mágica, hasta 60 pies de distancia, y puedes discernir colores en la oscuridad. Además, eres inmune a cegado.

A nivel 7, puedes afinar tu visión espectral al flujo de la magia a tu alrededor. Puedes usar tu acción para obtener los beneficios del conjuro *detectar magia* durante 10 minutos. Puedes usar esta característica dos veces. Recuperas todos los usos gastados cuando terminas un descanso corto o largo.

### Vil
A partir del nivel 2, puedes extraer energía vil caótica que duerme en tu interior. Tu acceso a esta fuerza caótica está representado por una cantidad de puntos de vil. Tu nivel de cazador de demonios determina la cantidad de puntos que tienes, como se muestra en la columna de Puntos de Vil de la tabla del Cazador de Demonios.

Puedes gastar estos puntos para alimentar varias características. Comienzas sabiendo tres de estas características: Mordida de Demonio, Potenciar Protecciones y Moméntum. Aprenderás más características de vil a medida que subas de nivel en esta clase.

Cuando gastas un punto de vil, no estará disponible hasta que termines un descanso corto o largo, al final del cual recuperarás toda tu energía vil gastada.

Algunas características de vil requieren que tu objetivo haga una tirada de salvación para resistir los efectos. La CD de salvación se calcula de la siguiente manera:

<div style="text-align: Center">

**CD de salvación de Vil** = <br>8 + Bonus competencia + Mod. Inteligencia
</div>

#### Mordida de Demonio
Inmediatamente después de realizar la acción de Ataque en tu turno, puedes gastar 1 punto de vil para hacer dos ataques con armas como acción adicional. No sumas tu modificador de habilidad al daño de estos ataques.

#### Potenciar Protecciones
Cuando haces una tirada de salvación de Inteligencia, Sabiduría o Carisma, puedes gastar 2 puntos de vil como reacción para obtener ventaja en la tirada de salvación.

#### Moméntum
Puedes gastar 1 punto de vil para realizar la acción de Desengancharse o Correr como acción adicional en tu turno, y tu distancia de salto se duplica durante ese turno.

### Metamorfosis
También en el nivel 2, eres capaz de liberar el poder de tu demonio atado. En tu turno, puedes entrar en metamorfosis como una acción adicional y transformarte en un ser demoníaco.

Mientras estés metamorfoseado, obtienes los siguientes beneficios:

 - Obtienes un número de puntos de golpe temporales igual a tu nivel de cazador de demonios + tu modificador de Inteligencia. Estos puntos de golpe duran mientras esté activa tu metamorfosis.
 - Tienes ventaja en las pruebas de Carisma (Intimidación).
 - Tus ataques con armas cuentan como mágicos para superar resistencias e inmunidades a ataques y daños no mágicos.
 - Cuando realizas un ataque con arma, infliges daño adicional por fuego que aumenta a medida que subes de nivel en esta clase, como se muestra en la columna de Daño de Metamorfosis de la tabla del Cazador de Demonios.
 - Tu velocidad de movimiento aumenta en 10 pies.

Tu metamorfosis dura 1 minuto. Termina antes si quedas inconsciente. También puedes finalizarla en tu turno como una acción adicional.

Puedes usar esta característica un número de veces igual al número que se muestra para tu nivel de cazador de demonios en la columna de Metamorfosis de la tabla de Cazador de Demonios. Recuperas todos los usos gastados después de terminar un descanso largo.

<div class='footnote'>CLASES | CAZADOR DE DEMONIOS</div>

<img src='https://hearthstone.wiki.gg/images/thumb/0/01/Metamorphosis_full.jpg/1280px-Metamorphosis_full.jpg' style='position:absolute; top:760px; right:-50px; width:530px' />
<img src='https://www.gmbinder.com/images/huxbNse.png' style='position:absolute; top:170px; right:0px; width:900px; transform:scaley(-1)' />
<img src='https://www.gmbinder.com/images/huxbNse.png' style='position:absolute; top:0px; right:-30px; width:900px; transform:scaley(-1)' />

\pagebreakNum

### Marca Demoníaca
A nivel 3, eliges una marca que moldea la naturaleza de tu cuerpo infundido demoníacamente. Elige la Marca de Devastación, la Marca de Venganza o la Marca de Ira, todas detalladas al final de la descripción de la clase.

Tu elección te otorga rasgos en el nivel 3 y nuevamente en los niveles 6, 10 y 17.

### Mejora de Característica
Cuando alcanzas el nivel 4, y nuevamente en los niveles 8, 12, 16 y 19, puedes aumentar una puntuación de característica de tu elección en 2, o puedes aumentar dos puntuaciones de característica de tu elección en 1. Como es habitual, no puedes aumentar una puntuación de característica por encima de 20 usando esta característica.

### Ataque Adicional
A partir del nivel 5, puedes atacar dos veces, en lugar de una, siempre que realices la acción de Ataque en tu turno.

### Hambre Instintiva
A partir del nivel 5, cuando una criatura termina su turno a 15 pies de ti, puedes usar tu reacción para moverte hasta la mitad de tu velocidad hacia un espacio más cercano a la criatura. Moverte de esta manera no provoca ataques de oportunidad.

Además, tienes ventaja en el primer ataque que realices contra la criatura antes del final de tu próximo turno.

### Evasión
A nivel 7, tus agudos reflejos te permiten esquivar ciertos efectos de área, como el aliento ardiente de un dragón rojo o el conjuro de *tormenta de hielo*. Cuando estés sujeto a un efecto que te permita hacer una tirada de salvación de Destreza para recibir solo la mitad del daño, en su lugar no recibes daño si tienes éxito en la tirada de salvación, y solo recibes la mitad del daño si fallas.

### Un Cazador por Encima de Todo
Al alcanzar el nivel 9, has perfeccionado tus instintos para cazar presas. Si pasas al menos 1 minuto observando a una criatura, obtienes ventaja en las pruebas de Sabiduría (Supervivencia) realizadas para rastrear a esa criatura hasta que la hayas matado, elijas una nueva presa o transcurran un número de días igual a tu nivel de cazador de demonios. Si pierdes el rastro de tu presa, puedes pasar 1 hora para percibir su dirección general en relación contigo, siempre y cuando ambos estén en el mismo plano de existencia.

Además, en tu primer turno durante el combate, tienes ventaja en las tiradas de ataque realizadas contra la criatura.

### Alas Demoníacas
A partir del nivel 11, puedes usar tu reacción cuando caigas para manifestar alas demoníacas, reduciendo cualquier daño por caída que recibas en una cantidad igual a cinco veces tu nivel de cazador de demonios.

Además, durante la duración de tu Metamorfosis, obtienes una velocidad de vuelo igual a tu velocidad de movimiento.

### Destreza Illidari
A partir del nivel 11, cuando empuñas un arma cuerpo a cuerpo con la propiedad versátil, puedes usar el valor de daño aumentado incluso cuando la empuñas con una mano. Si decides empuñar el arma con dos manos, no recibes ningún beneficio adicional.

### Purificado por las Llamas
En el nivel 13, puedes usar tu acción y gastar 2 puntos de vil para envolver tu cuerpo en llamas de dolor y finalizar un efecto en ti que te cause estar encantado, asustado o envenenado. Cada criatura en un radio de 5 pies de ti cuando uses esta característica debe realizar una tirada de salvación de Destreza, recibiendo 1d10 + la mitad de tu nivel de cazador de demonios en daño por fuego si falla, o la mitad del daño si tiene éxito.

### Mirada Reveladora
A partir del nivel 14, puedes concentrar el vil en tus ojos quemados para revelar la verdad del mundo que te rodea. Como acción, puedes gastar 3 puntos de vil para obtener los beneficios del conjuro *visión verdadera* durante 1 minuto.

### Resiliencia Abisal
En el nivel 15, has adquirido una fortaleza superior. Ganas competencia en tiradas de salvación de Constitución.

### Cuerpo Atemporal
A partir del nivel 18, el vil primordial que fluye por tu cuerpo te ha concedido una longevidad inimaginable. Por cada 10 años que pasen, tu cuerpo envejece solo 1 año y no puedes ser envejecido mágicamente.

### Preparado
A nivel 20, tus sentidos sobrenaturales te permiten actuar al <br> instante. Puedes tomar dos turnos durante la primera ronda de cualquier combate. Tomas tu primer turno en el conteo de iniciativa 30 y tu segundo turno en tu tirada de iniciativa.

Además, cuando tires iniciativa y no tengas puntos de vil restantes, recuperas 2 puntos de vil.

## Marca Demoníaca
Cada cazador de demonios ha absorbido el alma de un demonio y lucha una batalla continua por el control con este demonio. Aunque el cazador tiene el control, el demonio dentro de él se muestra y obliga a su cazador de demonios a asumir algunas de sus cualidades. Aunque las almas de los demonios son impredecibles, la mayoría caen en una de las siguientes categorías, dejando una marca de devastación, venganza o ira en el cazador de demonios.

<div class='footnote'>CLASES | CAZADOR DE DEMONIOS</div>

\pagebreakNum

### Marca de Devastación
Los cazadores de demonios con la Marca de Devastación liberan la potente energía almacenada dentro de ellos, siendo el pináculo del combate cuerpo a cuerpo. Canalizan el poder destructivo del vil para afianzar su control sobre el campo de batalla. Los cazadores marcados con devastación son conocidos por su naturaleza impredecible, velocidad inmensa y habilidad para canalizar el vil directamente en sus ataques.

#### Competencia Adicional
Al elegir esta marca en el nivel 3, obtienes competencia en la habilidad de Acrobacias si no la tienes. Tu bonificador de competencia se duplica en cualquier prueba de habilidad que uses con esta competencia.

#### Embestida Vil
A nivel 3, obtienes la capacidad de moverte a través del campo de batalla con tu momento. Siempre que gastes un punto de vil en la característica Moméntum, obtienes los beneficios de una acción de Esquivar y Desenganchar hasta el final de tu turno.

#### Moméntum Vengativo
A partir del nivel 6, siempre que uses la característica Moméntum de vil, obtienes ventaja en el siguiente ataque con arma que realices antes del final de tu próximo turno.

#### Danza de Cuchillas
A partir del nivel 10, obtienes la habilidad de atravesar distancias cortas en un parpadeo. Puedes gastar 1 punto de vil cuando realices la acción de Ataque en tu turno. Hasta el final de tu turno, puedes teletransportarte hasta 15 pies antes de cada ataque a un espacio desocupado que puedas ver.

Si atacas al menos a dos criaturas diferentes durante tu acción de Ataque, puedes realizar un ataque adicional contra una tercera criatura.

#### Nova del Caos
A nivel 17, cuando entras en metamorfosis, puedes liberar una ráfaga de energía caótica a tu alrededor. Cada criatura en un radio de 10 pies de ti debe tener éxito en una tirada de salvación de Constitución o quedar aturdida hasta el final de tu próximo turno.

\columnbreak

### Marca de Venganza
Los cazadores de demonios con la Marca de Venganza se fortalecen a través de las energías dentro de ellos; son cazadores que continúan luchando cuando todo lo demás falla. Al empoderarse, son capaces de recibir una enorme cantidad de golpes y aún así salir victoriosos al final de la batalla.

#### Competencia Adicional
Al elegir esta marca en el nivel 3, obtienes competencia en la habilidad de Intimidación si no la tienes. Tu bonificador de competencia se duplica para cualquier prueba de habilidad que realices con esta competencia.

#### Tormento
A nivel 3, obtienes la habilidad de atormentar a una criatura. Puedes usar tu acción para elegir una criatura que puedas ver dentro de 30 pies de ti. El objetivo debe tener éxito en una tirada de salvación de Sabiduría contra tu CD de salvación de vil o tener desventaja en las tiradas de ataque contra criaturas que no seas tú durante 1 minuto. Al final de cada uno de sus turnos, el objetivo puede realizar otra tirada de salvación, terminando el efecto en un éxito.

El tormento termina antes en el objetivo si usas esta habilidad en una criatura diferente.

#### Púas Demoníacas
A partir del nivel 6, tu forma demoníaca se ve potenciada por tu marca demoníaca, otorgándote resistencia al daño contundente, perforante y cortante mientras estás en metamorfosis. Además, mientras estés en metamorfosis, tienes ventaja en las pruebas y tiradas de salvación de Fuerza y Destreza.

#### Aura de Inmolación
Al alcanzar el nivel 10, puedes gastar 2 puntos de vil como acción adicional para envolver tu cuerpo en llamas viles. Cuando activas esta aura y al comienzo de cada uno de tus turnos mientras dura, recibes 1d6 puntos de daño por fuego. La aura de inmolación dura 1 minuto, hasta que la termines como acción adicional, o hasta que quedes inconsciente.

Siempre que una criatura te golpee con un ataque cuerpo a cuerpo mientras la aura de inmolación está activa, infliges a esa criatura un daño por fuego igual a 1d6 + la mitad de tu nivel de cazador de demonios.

#### Último Recurso
A nivel 17, puedes extraer vida de tu marca demoníaca para escapar de la muerte. Cuando te reduzcan a 0 puntos de golpe, puedes gastar 1 punto de vil (no se requiere ninguna acción) para quedarte con 1 punto de golpe en su lugar y entrar en tu metamorfosis hasta el final de tu próximo turno.

<div class='footnote'>CLASES | CAZADOR DE DEMONIOS</div>


<img src='https://hearthstone.wiki.gg/images/5/55/Chaos_Strike_full.jpg' style='position:absolute; top:740px; right:370px; width:530px;' />

<img src='https://www.gmbinder.com/images/huxbNse.png' style='position:absolute; top:130px; right:-100px; width:900px; transform:scaleX(-1); transform:scale(-1)' />

<img src='https://www.gmbinder.com/images/huxbNse.png' style='position:absolute; top:0px; right:-100px; width:900px; transform:scaleX(-1); transform:scale(-1)' />



\pagebreakNum

<div style='margin-top:150px;'></div>

### Marca de Ira
Los cazadores de demonios con la Marca de Ira extraen las energías caóticas infundidas en su piel, transformando el caos en llamas viles que pueden desatar sobre un objetivo desde la distancia. Canalizan el vil destructivo en una muestra despiadada de poder y agonía. Estos cazadores de demonios rara vez muestran el mismo hambre que otros Illidari 'nuevos'; tienen una presa en mente y no se detendrán hasta que esta ya no exista.

#### Competencia Adicional
Al elegir esta marca en el nivel 3, obtienes competencia en la habilidad de Arcanos si no la tienes. Tu bonificador de competencia se duplica para cualquier prueba de habilidad que uses con esta competencia.

#### Llamas del Caos
A nivel 3, aprendes a manifestar llamas viles puras. Obtienes una nueva opción de ataque que puedes usar con la acción de Ataque. Este ataque especial es un ataque a distancia con un arma con un alcance de 30 pies. Tienes competencia con él y añades tu modificador de Destreza a sus tiradas de ataque y daño. En un golpe exitoso, este ataque especial inflige 1d6 de daño por fuego.

Cuando obtienes la característica de Ataque Adicional, este ataque especial puede usarse para cualquiera de los ataques que realices como parte de la acción de Ataque.

A nivel 11, el daño de tus Llamas del Caos aumenta a 1d10 de daño por fuego.

\columnbreak

<div style='margin-top:150px;'></div>

#### Marca Ignea
A partir del nivel 6, tu metamorfosis potencia las llamas del caos que empuñas. Siempre que golpees a una criatura con un ataque de Llamas del Caos otorgado por tu Mordida de Demonio, la criatura debe tener éxito en una tirada de salvación de Constitución o tendrá desventaja en las tiradas de ataque hasta el final de su próximo turno.

Además, mientras estés en metamorfosis, el daño por fuego infligido por las llamas del caos ignora la resistencia al fuego y trata la inmunidad como resistencia para propósitos de daño.

#### Consumir Magia
A partir del nivel 10, puedes interferir y absorber magia. Como acción, puedes gastar 2 puntos de vil para crear los efectos de un conjuro *disipar magia*. Cuando disipas un efecto de esta manera, obtienes puntos de golpe temporales iguales al doble del nivel del conjuro + tu modificador de Inteligencia. Estos puntos de golpe permanecen hasta que termines un descanso corto o largo.


#### Barrera Vil
A nivel 17, puedes liberar un torrente de llamas del caos sobre los objetivos cercanos. Puedes usar tu acción y gastar de 1 a 5 puntos de vil para liberar una barrera de llamas del caos sobre las criaturas de tu elección dentro de 30 pies de ti. Cada criatura debe realizar una tirada de salvación de Destreza. En un fallo, la criatura recibe 1d8 de daño por fuego y 1d8 de daño por fuerza por cada punto de vil gastado, o la mitad del daño en un éxito.

<div style='margin-top:40px;'></div>

<div class='classTable wide'>


##### Armas Exóticas
|&nbsp; Nombre | Costo |&nbsp;&nbsp;&nbsp;&nbsp;| Daño | Peso |&nbsp;&nbsp;&nbsp;&nbsp;| Propiedades       &nbsp;|
|:--------------------------------------|---:|:-|:---------------|---:|:-:|:-------------------------------------|
|&nbsp; Guja           | 150 po|| 1d8 cortante   |  3 lb.|| Especial, Arrojadiza (alcance 20/60), Versátil (1d10)  |
</div>

### Armas Especiales
Las armas con reglas especiales se describen aquí.

***Guja.*** Cuando haces un ataque a distancia con una guja, regresa a tu mano al final de tu turno, a menos que hayas sacado un 1 natural en esa tirada de ataque. En ese caso, aterriza en el espacio de tu objetivo.

<div class='footnote'>CLASES | CAZADOR DE DEMONIOS</div>
<img src='https://www.gmbinder.com/images/9GF5zXj.jpg' style='position:absolute; top:-280px; right:0px; width:800px' />
<img src='https://www.gmbinder.com/images/3e9S91s.png' style='position:absolute; top:0px; right:0px; width:900px; transform:scaley(-1)' />
<img src='https://www.gmbinder.com/images/MhnBMAQ.png' style='position:absolute; top:800px; right:30px; width:400px' />

\pagebreakNum

<div style='margin-top:660px;'></div>

## Druida
*Ponerse en el camino de la naturaleza es una herejía. Incluso cuando la fuerza de la naturaleza es destructiva.*
<div style="text-align:Right"> 

*— Malfurion Tempestira* &nbsp;</div>

Empuñando un bastón grabado con hojas, un elfo de la noche invoca los poderes de Elune, aplastando a un enemigo con la energía de la luna y atrapándolo brevemente.

Agazapado en una rama baja, un huargen en forma de tigre vigila desde su escondite las construcciones de Zul'Gurub, observando los movimientos de los trols de la jungla.

Sosteniendo su hoz y bastón, una joven druida tauren realiza un ritual que hace brillar semillas en un círculo de luces verdes, sanando a un aliado herido.

Corriendo hacia su compañero, un trol se transforma en un oso gigante, bloqueando un golpe fatal con su pelaje.

\columnbreak

<div style='margin-top:150px;'></div>

### El Poder de la Naturaleza
Los druidas canalizan los poderes de la naturaleza para preservar el equilibrio y proteger la vida. Pueden desatar energía natural contra sus enemigos, atándolos con enredaderas o atrapándolos en ciclones, o dirigir ese poder para sanar y revivir aliados.

Están profundamente sintonizados con los espíritus animales de Azeroth. Como maestros de la metamorfosis, los druidas pueden adoptar la forma de una variedad de bestias, transformándose en osos, felinos, criaturas acuáticas y criaturas del aire con facilidad. Esta flexibilidad les permite desempeñar diferentes roles durante sus aventuras, desgarrando enemigos en un momento y explorando el campo de batalla desde el cielo al siguiente. Estos guardianes del orden natural están entre los héroes más versátiles de Azeroth y deben estar preparados para adaptarse a nuevos desafíos en un instante.

### Protectores del Equilibrio
Guardianes de la naturaleza que buscan preservar el equilibrio y proteger la vida, los druidas tienen una versatilidad inigualable en el campo de batalla. Esto se debe en parte a que el druidismo es mucho más que una disciplina de combate. Es una forma de vida impregnada de tradiciones tan antiguas que incluso el origen de su tipo se preserva en gran parte en mitología transmitida a lo largo de milenios.

Los druidas canalizan la energía cruda de la naturaleza para un increíble rango de habilidades ofensivas y defensivas, así como para restaurar la vida a los heridos. A través de la comunión con la naturaleza y el semidiós Cenarius, Señor del Bosque, los druidas están dotados sobrenaturalmente con el don de la metamorfosis, lo que les permite tomar la forma de todo tipo de criaturas de la naturaleza y acceder a poderes tan distintos como diversos.

### Crear un Druida
Mientras creas tu personaje druida, considera el vínculo que tienes con el mundo natural que te rodea. ¿Quizás siempre encontraste consuelo en las bestias salvajes y pasaste mucho tiempo en la forma de un animal, imitando a la propia naturaleza? ¿Quizás tu hogar fue devastado por invasores y buscaste las fuerzas de la naturaleza para ayudar a reconstruir lo que se perdió, buscando restaurar lo que ha sido dañado? O tal vez fuiste criado por los fieles de Elune y abrazaste a la diosa como propia. Quizás tu personaje nació en las profundidades de los bosques élficos, lo que fue interpretado como una señal de que convertirse en druida era parte de su destino.

¿Siempre has sido un aventurero como parte de tu llamado druídico, o primero pasaste tiempo como cuidador de un bosque sagrado? ¿O tal vez te convertiste en aventurero para encontrar tu vínculo con la naturaleza en otros lugares del mundo?

<div class='footnote'>CLASES | DRUIDA</div>
<img src='https://www.gmbinder.com/images/NYEBlxm.jpg' style='position:absolute; top:0px; right:100px; width:1350px' />
<img src='https://www.gmbinder.com/images/pbSeYXZ.png' style='position:absolute; top:0px; right:0px; width:900px' />
<img src='https://www.gmbinder.com/images/9wnUwNO.png' style='position:absolute; top:0px; right:-50px; width:900px' />
<img src='https://www.gmbinder.com/images/3EnvB2R.png' style='position:absolute; top:60px; right:390px; width:500px' />

\pagebreakNum

<div class='classTable wide'>

##### El Druida
| Nivel | Bonus de <br> competencia | Rasgos | Conjuros<br>Conocidos |&nbsp;|1º|&nbsp;|2º|&nbsp;|3º|&nbsp;|4º|&nbsp;|5º |&nbsp;|6º|&nbsp;|7º|&nbsp;|8º|&nbsp;|9º|&nbsp;|Afinidades<br> Conocidas <div style="position: absolute; top:90px; right:130px; width:200px; height:25px">—Espacios de Conjuros por Nivel—</div>|
|:---:|:--:|:----------------------------------------------------------|:--:|-|:-:|-|:-:|-|:-:|-|:-:|-|:-:|-|:-:|-|:-:|-|:-:|-|:-:|-|:---:|
| 1  | +2 | Druidismo, Lanzamiento de Conjuros                           |2||2||—||—||—||—||—||—||—||—||—|
| 2  | +2 | Cambio de Forma, Senda del Druida                            |2||3||—||—||—||—||—||—||—||—||—|
| 3  | +2 | Afinidades Salvajes                                          |2||4||2||—||—||—||—||—||—||—||2|
| 4  | +2 | Mejora de Característica, <br> Mejora de Cambio de forma     |3||4||3||—||—||—||—||—||—||—||2|
| 5  | +3 | —                                                            |3||4||3||2||—||—||—||—||—||—||2|
| 6  | +3 | Rasgo de la Senda del Druida                                 |3||4||3||3||—||—||—||—||—||—||2|
| 7  | +3 | —                                                            |3||4||3||3||1||—||—||—||—||—||3|
| 8  | +3 | Mejora de Característica, <br> Mejora de Cabmio de forma     |3||4||3||3||2||—||—||—||—||—||3|
| 9  | +4 | —                                                            |3||4||3||3||3||1||—||—||—||—||3|
| 10 | +4 | Rasgo de la Senda del Druida                                 |4||4||3||3||3||2||—||—||—||—||3|
| 11 | +4 | —                                                            |4||4||3||3||3||2||1||—||—||—||4|
| 12 | +4 | Mejora de Característica                                     |4||4||3||3||3||2||1||—||—||—||4|
| 13 | +5 | —                                                            |4||4||3||3||3||2||1||1||—||—||4|
| 14 | +5 | Rasgo de la Senda del Druida                                 |4||4||3||3||3||2||1||1||—||—||4|
| 15 | +5 | —                                                            |4||4||3||3||3||2||1||1||1||—||5|
| 16 | +5 | Mejora de Característica                                     |4||4||3||3||3||2||1||1||1||—||5|
| 17 | +6 | —                                                            |4||4||3||3||3||2||1||1||1||1||5|
| 18 | +6 | Cuerpo Atemporal, <br> Alma del Bosque                       |4||4||3||3||3||3||1||1||1||1||5|
| 19 | +6 | Mejora de Característica                                     |4||4||3||3||3||3||2||1||1||1||6|
| 20 | +6 | Rasgo de la Senda del Druida                                 |4||4||3||3||3||3||2||2||1||1||6|
</div>

#### Creación Rápida
Haz que Sabiduría sea tu característica principal, seguida por la Constitución. (Algunos druidas que se centran más en su fuerza física que mental prefieren hacer que la Fuerza o Destreza sea más alta que la Sabiduría). Elige el trasfondo de ermitaño.

#### Multiclase

&nbsp;&nbsp;&nbsp;&nbsp;***Característica Minima.*** Necesitas al menos 13 en Sabiduría para coger un nivel en druida o en otra clase si ya eres druida.

***Competencias Ganadas.*** Armadura ligera, habilidad de naturaleza.

***Espacios de Conjuros.*** Suma tus niveles de druida (o la mitad si eliges Senda del Feral) a los niveles de otras clases para calcular los espacios de conjuros disponibles.

\columnbreak

<div style='margin-top:-10px;'></div>

## Rasgos de Clase

#### Puntos de Golpe
___
- **Dados de Golpe:** 1d8 por nivel de druida
- **PG al nivel 1:** 8 + Mod. Constitución
- **PG por nivel:** 1d8 (o 5) + Mod. Constitución por nivel de druida

#### Competencias
___
- **Armadura:** Armadura ligera
- **Armas:** Armas simples
- **Herramientas:** Kit de herboristería
- **Tiradas de Salvación:** Inteligencia, Sabiduría
- **Habilidades:** Elige dos de las siguientes: Arcanos, Trato con Animales, Perspicacia, Medicina, Naturaleza, Percepción, Religión y Supervivencia

#### Equipo
- *(a)* un bastón o *(b)* cualquier arma simple
- *(a)* una daga o *(b)* cualquier arma simple
- Armadura de cuero, un paquete de explorador y un foco druídico

<div class='footnote'>CLASES | DRUIDA</div>

\pagebreakNum

### Druídico
Conoces el druídico, el lenguaje secreto de los druidas. Puedes hablar, leer y escribir en druídico, un lenguaje sagrado para los druidas que no se enseña a los forasteros sin severas consecuencias para el maestro y el aprendiz.

### Lanzamiento de Conjuros
Al canalizar la esencia divina de la propia naturaleza, puedes lanzar conjuros para moldear esa esencia a tu voluntad. Consulta el capítulo 10 del *Manual del Jugador* para conocer las reglas generales sobre lanzamiento de conjuros y el capítulo 6 de este libro para ver la lista de conjuros de los druidas.

#### Trucos
Al nivel 1, conoces dos trucos de tu elección de la lista de conjuros de druida. Aprendes trucos adicionales de druida a niveles superiores, como se muestra en la columna Trucos Conocidos de la tabla del Druida.

#### Preparación y Lanzamiento de Conjuros
La tabla de Druida muestra cuántos espacios de conjuro tienes para lanzar tus conjuros de nivel 1 o superior. Para lanzar un conjuro de druida, debes gastar un espacio de conjuro del nivel del conjuro o superior. Recuperas todos los espacios de conjuro gastados cuando terminas un descanso largo.

Preparas la lista de conjuros de druida que tienes disponibles para lanzar eligiendo de la lista de conjuros de druida. Al hacerlo, elige un número de conjuros de druida igual a tu modificador de Sabiduría + tu nivel de druida (mínimo de un conjuro). Los conjuros deben ser de un nivel para el cual tienes espacios de conjuro.

Por ejemplo, si eres un druida de nivel 3, tienes cuatro espacios de conjuro de nivel 1 y dos de nivel 2. Con una Sabiduría de 16, tu lista de conjuros preparados puede incluir seis conjuros de nivel 1 o 2, en cualquier combinación. Si preparas el conjuro de nivel 1 *curar heridas*, puedes lanzarlo usando un espacio de nivel 1 o 2. Lanzar el conjuro no lo elimina de tu lista de conjuros preparados. 

También puedes cambiar tu lista de conjuros preparados cuando terminas un descanso largo. Preparar una nueva lista de conjuros de druida requiere tiempo de oración y meditación: al menos 1 minuto por nivel de conjuro para cada conjuro en tu lista.

#### Habilidad de Lanzamiento de Conjuros
La Sabiduría es tu habilidad de lanzamiento de conjuros para tus conjuros de druida, ya que tu magia se basa en tu devoción y conexión con la naturaleza. Utilizas tu modificador de Sabiduría siempre que un conjuro se refiera a tu habilidad de lanzamiento de conjuros. Además, utilizas tu modificador de Sabiduría al establecer la CD de salvación de un conjuro de druida que lances y al realizar una tirada de ataque con uno.

<div style="text-align: Center">

**CD de salvación de conjuro** = <br>8 + Bonus competencia + Mod. Sabiduría

**Modificador de ataque de conjuro** = <br>Bonus competencia + Mod. Sabiduría
</div>

\columnbreak

#### Lanzamiento de Rituales
Puedes lanzar un conjuro de druida como ritual si dicho conjuro tiene la etiqueta de ritual y lo tienes preparado.

#### Enfoque de Lanzamiento de Conjuros
Puedes usar un foco druídico como enfoque para lanzar tus conjuros de druida.

### Cambio de forma
A partir del 2º nivel, puedes usar tu acción para asumir mágicamente una forma druídica. No hay límite en cuántas veces puedes cambiar de forma a una que conozcas.

Tu nivel de druida determina las formas a las que puedes transformarte, como se muestra en la tabla de Formas de Cambio. Por ejemplo, al 2º nivel, puedes cambiar a la forma de un gato o un oso, entre otras.

##### Cambio de forma
|&nbsp; Nivel |&nbsp;&nbsp;| Formas Disponibles |
|:----------:|:-|:------------------------------------|
|&nbsp; 2    |  | Gato, Oso, Lechúcico Lunar, Árbol   |
|&nbsp; 4    |  | Acuática, Viaje                     |
|&nbsp; 8    |  | Vuelo                               |

No hay límite en cuánto tiempo puedes permanecer transformado, y puedes regresar a tu forma normal como acción adicional. Revertirás automáticamente si quedas inconsciente, caes a 0 puntos de golpe o mueres.

Mientras estás transformado, se aplican las siguientes reglas:

- Conservas tus estadísticas de juego, alineamiento y personalidad. Mientras estás en forma de cambio, se te considera sin armadura y calculas tu Clase de Armadura según la forma.
- Cuando cambias de forma, tus puntos de golpe no cambian, y cualquier daño recibido en una forma se transfiere a tu forma normal.
- No puedes lanzar conjuros, a menos que la forma lo indique, y tu capacidad para hablar o realizar acciones que requieran manos se limita a las capacidades de tu forma. Sin embargo, cambiar de forma no rompe tu concentración en un conjuro que ya hayas lanzado ni te impide realizar acciones que formen parte de un conjuro, como *rayo de luna*, que ya hayas lanzado.
- Conservas el beneficio de cualquier característica de tu clase, raza u otra fuente y puedes usarlas si la forma es físicamente capaz de hacerlo, además de ganar las características de la forma. Sin embargo, no puedes usar tus sentidos especiales, como visión en la oscuridad, a menos que tu nueva forma también posea ese sentido.
- Eliges si tu equipo cae al suelo en tu espacio, se fusiona con tu nueva forma o es usado por ella. El equipo usado funciona con normalidad, pero el DM decide si es práctico para la nueva forma usar una pieza de equipo, según la forma y el tamaño de la criatura. Tu equipo no cambia de tamaño ni forma para coincidir con la nueva forma, y cualquier equipo que la nueva forma no pueda usar debe caer al suelo o fusionarse con ella. El equipo fusionado con tu forma no tiene efecto y no puede ser activado hasta que salgas de la forma, pero cualquier propiedad mágica pasiva seguirá afectándote.

<div class='footnote'>CLASES | DRUIDA</div>

\pagebreakNum

### Sendas del Druida
A partir del 2º nivel, eliges una senda druídica: Equilibrio, Feral o Restauración, cada una de las cuales se detalla al final de la descripción de la clase. Tu elección te otorga características en el 2º nivel y de nuevo en el 6º, 10º, 14º y 20º nivel.

### Afinidades Salvajes
Al haber acostumbrado tu ser a las fuerzas druídicas, has aprendido a aprovechar el verdadero potencial de sus poderes y el potencial de ciertas formas.

En el 3er nivel, obtienes dos afinidades salvajes de tu elección. Las opciones de afinidad se detallan al final de la descripción de la clase. Cuando alcanzas ciertos niveles de druida, obtienes afinidades adicionales de tu elección, como se muestra en la columna de Afinidades Conocidas de la tabla del Druida.

Además, cuando subes de nivel en esta clase, puedes elegir una de las afinidades que conoces y reemplazarla con otra afinidad que podrías aprender en ese nivel.

> ##### Formas Druídicas
> Los cambios de forma son una extensión del druida. Tanto a nivel personal como racial, las transformaciones de un tauren pueden incluir cuernos similares a los suyos, un orco o trol puede añadir colmillos, mientras que un elfo nocturno podría decorarlas con signos de Elune, y así sucesivamente. Asimismo, sus formas bestiales podrían variar: un elfo nocturno podría optar por un pantera esbelta, mientras que un tauren escogería un león robusto.
>
> Ciertas formas no tienen que ser transformaciones imponentes. Un druida que cambia de forma a luniscente podría no convertirse en un búho gigante, sino tomar cualidades de Elune, con ojos que brillan en plata y una piel cubierta por puntos de luz estrellada. Un druida que asuma la forma de un árbol puede transformar su piel en corteza, su cabello en hojas, y así.
>
> Las formas de cambio son tuyas para personalizar. Aunque cada una esté vinculada a un tipo de animal o criatura, puedes modificar su apariencia para que se ajuste mejor a tu raza, o hablar con tu DM sobre hacerla completamente diferente.

### Mejora de Caracteristica
Cuando alcanzas el nivel 4, y de nuevo en los niveles 8, 12, 16 y 19, puedes aumentar una puntuación de caracteristica de tu elección en 2, o puedes aumentar dos puntuaciones de caracteristica de tu elección en 1. No puedes aumentar una puntuación de caracteristica por encima de 20 usando este procedimiento.

### Cuerpo Atemporal
A partir del nivel 18, la magia primigenia que manejas ha hecho que envejezcas más lentamente. Por cada 10 años que pasan, tu cuerpo envejece solo 1 año.

\columnbreak


### Alma del Bosque
A partir del nivel 18, tu conexión con la naturaleza crece a nuevas profundidades, fortaleciendo tu vínculo con ella y permitiéndote conjurar un portal al Sueño Esmeralda.

Si pasas 10 minutos en un área de naturaleza intacta, puedes conjurar un portal al Sueño Esmeralda. La entrada brilla tenuemente y mide 5 pies de ancho y 10 pies de alto. Tú y cualquier criatura que designes al conjurar el portal pueden entrar al Sueño Esmeralda mientras el portal permanezca abierto. Puedes abrir y cerrar el portal si estás a menos de 30 pies de él. Cuando está cerrado, el portal en Azeroth se desmorona y es efectivamente invisible. El portal permanece conjurado durante 24 horas, después de lo cual se desmorona por completo y no puede ser conjurado nuevamente durante 7 días.

Además, las bestias y plantas del mundo natural perciben tu conexión con la naturaleza, dándote ventaja en todas las pruebas de habilidad y habilidad realizadas para comunicarte con ellas.

## <span style="margin-left:25px"></span> Caminos del Druida
Aunque todos los druidas tienen un profundo amor por la naturaleza y 
la vida salvaje, algunos sienten un amor especial por las bestias del 
mundo e imitan sus formas. Otros tienen un vínculo profundo con la 
diosa Elune y algunos desean preservar la vida. Todos los druidas pueden 
situarse dentro de uno de los siguientes caminos: Equilibrio, Feral o Restauración.

<div class='footnote'>CLASES | DRUIDA</div>

<img src='https://hearthstone.wiki.gg/images/0/0a/Mark_of_the_Wild_full.jpg' style='position:absolute; top:490px; right:-180px; width:670px' />
<img src='https://www.gmbinder.com/images/wvTUmvu.png' style='position:absolute; top:5px; right:0px; width:800px' />
<img src='https://www.gmbinder.com/images/E8GrMME.png' style='position:absolute; top:0px; right:0px; width:900px' />

\pagebreakNum


### Camino del Equilibrio
Los druidas en el Camino del Equilibrio se convierten en combatientes feroces capaces de invocar las fuerzas de la naturaleza y la querida diosa Elune para guiar sus manos. Muchos de estos druidas tienen una conexión profunda con el mundo natural y trabajan para protegerlo de las muchas amenazas externas.

##### Conjuros del Camino del Equilibrio
|&nbsp; Nivel de Druida |&nbsp;&nbsp;| Conjuros            |
|:--------:|:-|:---------------------------------------------------|
|&nbsp; 3  |  | *habilidad mejorada, rayo de luna*                 |
|&nbsp; 5  |  | *luz del día, ✦ estallido estelar*                 |  
|&nbsp; 7  |  | *confusión, enredadera atrapadora*                 |
|&nbsp; 9  |  | *comulgar con la naturaleza, ira de la naturaleza* |
<div style='margin-top:-5px;'></div>

*✦ Los nuevos conjuros se encuentran en el capítulo 6 más adelante en este libro* 

#### Conjuros del Camino
Tu conexión mística con Elune te infunde con la habilidad para lanzar ciertos conjuros. En el 3º, 5º, 7º y 9º nivel, obtienes acceso a conjuros del camino.

Una vez que tienes acceso a un conjuro del camino, siempre lo tienes preparado y no cuenta contra el número de conjuros que puedes preparar cada día.

#### Invocar
A partir del 2º nivel, puedes recuperar parte de tu energía mágica meditando y comulgando con la naturaleza. Durante un descanso corto, puedes elegir espacios de conjuro gastados para recuperar. Los espacios de conjuro pueden tener un nivel combinado igual o inferior a la mitad de tu nivel de druida (redondeado hacia arriba), y ninguno de los espacios puede ser de nivel 6 o superior. No puedes usar esta característica nuevamente hasta que termines un descanso largo.

Por ejemplo, cuando eres un druida de nivel 4, puedes recuperar hasta dos niveles de espacios de conjuro. Puedes recuperar un espacio de nivel 2 o dos espacios de nivel 1.

#### Fuerza de la Naturaleza
A partir del 6º nivel, puedes aprovechar las fuerzas que te rodean para potenciar tus hechizos.

Cuando lanzas un conjuro que tiene como objetivo solo una criatura, puedes elegir infligir daño adicional igual a tu nivel de druida o restaurar puntos de golpe a ella igual a tu nivel de druida. Puedes usar esta característica antes o después de una tirada de ataque, pero antes de que se apliquen los efectos de la tirada.

Puedes usar esta característica dos veces. Recuperas los usos gastados cuando terminas un descanso largo.

\columnbreak

#### Influencia Astral
Al alcanzar el 10º nivel, encuentras consuelo y poder en la diosa Elune, obteniendo las siguientes características.

- Ganas resistencia al daño radiante.
- Puedes elegir infligir daño radiante con tu característica Fuerza de la Naturaleza, en lugar del tipo de daño del conjuro.
- Tienes ventaja en las pruebas y tiradas de salvación para evitar ser encantado o asustado por efectos de conjuros.
<div style='margin-top:-4px;'></div>

#### Bendición de los Ancestros
A partir del 14º nivel, equilibras las dos fuerzas del mundo. Siempre que terminas un descanso corto o largo, puedes elegir *an'she* o *elune* y obtener los beneficios del equilibrio elegido hasta que termines tu próximo descanso.

***An'she.*** Siempre estás bajo los efectos de un conjuro de *ver lo invisible*. Además, eres inmune a la ceguera y cuando se hace un ataque cuerpo a cuerpo contra ti, puedes usar tu reacción para imponer desventaja en la tirada de ataque.

***Elune.*** Obtienes visión en la oscuridad con un alcance de 60 pies. Si ya tienes visión en la oscuridad debido a tu raza, su alcance aumenta en 30 pies. Además, mientras estés en penumbra u oscuridad, puedes usar tu reacción para obtener ventaja en tus ataques de hechizo hasta el final de tu turno.

#### Encarnación: Elegido de Elune
En el nivel 20, has sido elegido por Elune y puedes dejar que sus poderes fluyan a través de ti, tomando una apariencia según tu elección. Por ejemplo, los colores y las estrellas de Elune podrían moverse por tu piel, tu forma de luniscente podría brillar con una luz tenue azulada, o podrías tener una luna creciente flotando sobre tu cabeza.

Puedes usar tu acción para asumir tu forma de luniscente y permitir que los poderes de la diosa fluyan a través de ti. Durante 1 minuto, obtienes los siguientes beneficios:

- Puedes usar un espacio de conjuro para lanzar el hechizo *rayo de luna*, incluso si no lo tienes preparado, y puedes mover el rayo como una acción adicional.
- El alcance de cualquier hechizo de druida que lances se duplica, y cualquier hechizo de druida con un alcance de toque tiene un alcance de 30 pies.
- Tienes ventaja en tiradas de salvación de Sabiduría, al igual que tus aliados dentro de un radio de 30 pies.

La encarnación persiste más allá de la transformación, pero no tiene efecto fuera de tu forma de luniscente. Una vez que usas esta característica, no puedes volver a usarla hasta que termines un descanso largo.

<div class='footnote'>CLASES | DRUIDA</div>
<img src='https://www.gmbinder.com/images/QGRe8vc.png' style='position:absolute; top:1050px; right:330px; width:750px;transform:rotate(-105deg)' />

\pagebreakNum

<div style='margin-top:480px;'></div>

<div class='classTable'>

##### Conjuración Feral
|Nivel <br> de Druida|Trucos <br> Conocidos|1º|&nbsp;|2º|&nbsp;|3º|&nbsp;|4º|&nbsp;|5º|&nbsp;|Afinidades <br> Conocidas|
|:--:|:--:|:--:|-|:--:|-|:--:|-|:--:|-|:--:|-|:--:|
| 2  | 2  |3 ||—||—||—||—||—|
| 3  | 2  |3 ||—||—||—||—||2|
| 4  | 2  |3 ||—||—||—||—||2|
| 5  | 2  |4 ||2||—||—||—||3|
| 6  | 2  |4 ||2||—||—||—||3|
| 7  | 2  |4 ||3||—||—||—||4|
| 8  | 2  |4 ||3||—||—||—||4|
| 9  | 2  |4 ||3||2||—||—||5|
| 10 | 3  |4 ||3||2||—||—||5|
| 11 | 3  |4 ||3||3||—||—||6|
| 12 | 3  |4 ||3||3||—||—||6|
| 13 | 3  |4 ||3||3||1||—||7|
| 14 | 3  |4 ||3||3||1||—||7|
| 15 | 3  |4 ||3||3||2||—||8|
| 16 | 3  |4 ||3||3||2||—||8|
| 17 | 3  |4 ||3||3||3||1||9|
| 18 | 3  |4 ||3||3||3||1||9|
| 19 | 3  |4 ||3||3||3||2||10|
| 20 | 3  |4 ||3||3||3||2||10|
</div>

### Camino Feral
Los druidas del Camino Feral sienten una conexión más profunda con la naturaleza salvaje y sus criaturas que otros druidas, prefiriendo la forma de un animal feroz por encima de su ser humanoide. Los druidas ferales sobresalen en el combate cuerpo a cuerpo y utilizan todas las capacidades de sus transformaciones para atacar a sus enemigos de frente.

#### Adaptación Salvaje
Cuando eliges este camino en el nivel 2, obtienes competencia en tus elecciones de salvaciones de Destreza o Constitución, además de las del druida.

Además, te refieres a la tabla de Conjuración Feral en la descripción de la clase Feral para determinar tus cantrips, espacios de conjuro y afinidades conocidas cada vez que subas de nivel en esta clase. También cuentas como un *medio lanzador* para determinar los espacios de conjuro disponibles al combinarte con otras clases.

#### Marca de Ursol
A partir del nivel 2, puedes canalizar la sabiduría del antiguo Ursol para permitirte lanzar hechizos sutilmente, incluso mientras estás transformado.

Puedes usar esta característica para lanzar hechizos mientras estás transformado hasta el final de tu turno. Mientras está activa, ignoras los componentes verbales y somáticos de tus hechizos de druida, así como cualquier componente material que no tenga un costo y que no se consuma por el hechizo.

Puedes usar esta característica dos veces. Recuperas los usos gastados cuando terminas un descanso corto o largo.

#### Afinidad Feral o Guardiana
También en el nivel 2, obtienes una de las siguientes características a tu elección, la cual también determinará tu característica de Feral del nivel 14.

***Ravager.*** Cuando golpeas a una criatura con un ataque cuerpo a cuerpo mientras estás transformado, puedes gastar un espacio de conjuro para infligir daño adicional al objetivo. El daño adicional es de 2d8 por un espacio de conjuro de nivel 1, más 1d8 por cada nivel de hechizo superior al 1º, hasta un máximo de 6d8.

***Frenesí.*** Puedes usar una acción adicional para entrar en un frenesí mientras estás transformado, lo que te da resistencia al daño contundente, perforante y cortante.

Tu frenesí dura 1 minuto. Termina antes si quedas inconsciente o si tu turno termina y no has atacado a una criatura hostil desde tu último turno o no has recibido daño desde entonces. También puedes finalizar el frenesí en tu turno como acción adicional.

Puedes usar esta característica dos veces. A partir del nivel 7, puedes usar el frenesí tres veces entre descansos, y en el nivel 15, puedes entrar en un frenesí cuatro veces entre descansos. Cuando termines un descanso largo, recuperas todos los usos gastados.

#### Instintos Primales
Al alcanzar el nivel 6, actúas instintivamente ante el peligro y sumas tu modificador de Sabiduría a tus tiradas de iniciativa.

Tu tiempo pasado transformado te ha hecho hábil para escudriñar tu entorno. No puedes ser sorprendido mientras estés despierto.

<div class='footnote'>CLASES | DRUIDA</div>

<img src='https://www.gmbinder.com/images/cTUhYzO.jpg' style='position:absolute; top:0px; right:370px; width:450px' />
<img src='https://www.gmbinder.com/images/fnPL7gX.png' style='position:absolute; top:0px; right:-100px; width:900px; transform:scaley(-1)' />

\pagebreakNum

#### Ataque Adicional
A partir del nivel 6, puedes atacar dos veces, en lugar de una, siempre que realices la acción de Ataque en tu turno mientras estás transformado.

Además, tus ataques con armas transformado cuentan como mágicos a efectos de superar resistencias e inmunidades a los ataques y daños no mágicos.

#### Tácticas Férales
También en el nivel 6, eliges una de las siguientes características. Puedes usar esta característica cuando estás transformado.

***Defensor de la Manada.*** Cuando una criatura amiga que puedes ver a 5 pies de ti sea objetivo de una tirada de ataque, puedes usar tu reacción para intercambiar lugares con la criatura y que el ataque te apunte a ti en su lugar.

***Demoledor Pulverizante.*** Cuando golpeas a una criatura con un ataque de arma, la criatura debe hacer una tirada de salvación de Fuerza (CD 8 + tu modificador de Fuerza o Destreza + tu bonificador de competencia). Si falla, la criatura cae derribada. Solo puedes pulverizar una vez por turno.

#### Mutilación Brutal
En el nivel 10, cuando golpeas a una criatura con un ataque de arma mientras estás transformado, la criatura golpeada tiene desventaja en la próxima tirada de salvación que haga contra un hechizo de druida que lances antes del final de tu siguiente turno.

#### Afinidad Superior Feral o Guardiana
A partir del nivel 14, obtienes una de las siguientes características, según tu elección en el nivel 2.

***Ravager.*** Cuando una criatura hostil que puedes ver a tu alcance sea golpeada por un ataque realizado por otra criatura, puedes usar tu reacción para hacer un ataque de oportunidad contra esa criatura hostil.

***Frenesí.*** Mientras estás en frenesí, cualquier criatura a 5 pies de ti que sea hostil hacia ti tiene desventaja en las tiradas de ataque contra objetivos que no seas tú u otro personaje con esta característica. Un enemigo es inmune a este efecto si no puede verte u oírte o si no puede ser asustado.

\columnbreak

#### Encarnación: Guardián de las Tierras Salvajes
En el nivel 20, puedes asumir la forma de un guardián de las tierras salvajes, mejorando la apariencia de tu transformación y empoderándote a través de las fuerzas de la naturaleza. La corteza se manifiesta como una armadura alrededor de ti y tu apariencia se vuelve feroz y aterradora a medida que las tierras salvajes te otorgan su poder.

Mientras estás transformado, puedes usar tu acción para encarnar las tierras salvajes. Durante 1 minuto, obtienes los siguientes beneficios:

- Cuando realizas la acción de Ataque en tu turno, puedes hacer un ataque adicional como parte de esa acción.
- Todas las tiradas de ataque tienen desventaja contra ti, ya que la armadura de corteza toma el frente de los golpes.
- Tu velocidad base aumenta en 10 pies y puedes ignorar el terreno difícil.

La encarnación persiste más allá de tus transformaciones, pero no tiene efecto fuera de ellas. Una vez que usas esta característica, no puedes usarla nuevamente hasta que termines un descanso largo.

<div class='footnote'>CLASES | DRUIDA</div>

\pagebreakNum

### Camino de la Restauración
Los druidas del Camino de la Restauración buscan deshacer las muchas heridas infligidas al mundo y a su gente. Son individuos de gran corazón y amorosos, menos propensos a ataques de ira y más dispuestos a buscar un terreno común.

##### Hechizos del Camino de la Restauración
|&nbsp; Nivel de Druida |&nbsp;&nbsp;| Hechizos        |
|:---------:|:-|:--------------------------------|
|&nbsp; 3  || corteza de árbol, restauración menor |
|&nbsp; 5  || palabra curativa en masa, revivificar|
|&nbsp; 7  || aura de vida, guardián de la naturaleza|
|&nbsp; 9  || restauración mayor, resucitar       |

#### Hechizos del Camino
Tus poderes restaurativos te han otorgado la capacidad de lanzar ciertos hechizos en tu beneficio. En el nivel 3, 5, 7 y 9 obtienes acceso a los hechizos del camino.

Una vez que obtienes acceso a un hechizo del camino, siempre lo tienes preparado y no cuenta para el número de hechizos que puedes preparar cada día.

#### Rejuvenecimiento
Cuando eliges este camino en el nivel 2, recibes las bendiciones de Elune, convirtiéndote en una fuente de energía que ofrece alivio de las heridas. Tienes una reserva de energía representada por un número de d6 igual a tu nivel de druida.

Como acción adicional, puedes elegir una criatura que puedas ver a 120 pies de ti y gastar un número de esos dados igual a la mitad de tu nivel de druida o menos. Lanza los dados gastados y súmalos. El objetivo recupera una cantidad de puntos de golpe igual al total. El objetivo también gana 1 punto de golpe temporal por dado.

Recuperas todos los dados gastados cuando terminas un descanso largo.

#### Corteza de Hierro
A partir del nivel 6, cuando tú o una criatura dentro de 30 pies de ti reciban daño por ácido, frío, fuego, relámpago o trueno, puedes usar tu reacción para otorgar resistencia a la criatura contra esa instancia del daño.

\columnbreak

#### Tranquilidad
A partir del nivel 10, puedes recurrir a la naturaleza tranquila que te rodea para calmar a tus aliados. Como acción, invocas la tranquilidad y obtienes una reserva de energía de curación que puede restaurar puntos de golpe igual a cinco veces tu nivel de druida.

Mantener la tranquilidad requiere tu concentración, dura hasta 1 minuto, y mientras estás concentrado en ella, tu velocidad de movimiento se reduce a la mitad.

Mientras esté activa, puedes usar una acción adicional para elegir cualquier número de criaturas dentro de 30 pies de ti y dividir un número de puntos de golpe de tu reserva entre ellas, hasta un máximo de puntos de golpe igual a tu nivel de druida. 

Una vez que usas esta característica, no puedes usarla nuevamente hasta que termines un descanso largo.

#### Guardia Cenarion
Cuando alcanzas el nivel 14, las criaturas del mundo natural sienten tu conexión con la naturaleza y se vuelven reticentes a atacarte. Cuando una bestia o planta te ataque, la criatura debe hacer una tirada de salvación de Sabiduría contra la CD de salvación de tus hechizos de druida. Si falla, la criatura debe elegir un objetivo diferente o el ataque falla automáticamente. Si tiene éxito, la criatura es inmune a este efecto durante 24 horas.

La criatura es consciente de este efecto antes de realizar su ataque contra ti.

#### Encarnación: Arbol de Vida
Al llegar al nivel 20, puedes obtener fuerza de los árboles del mundo de Azeroth, aumentando tu forma de árbol a igualar a un anciano mientras asumes la forma serena de un Árbol de la Vida.

Puedes usar tu acción para asumir tu forma de árbol y encarnar el Árbol de la Vida. Durante 1 minuto, obtienes los siguientes beneficios:

- Al comienzo de cada uno de tus turnos, ganas 10 puntos de golpe temporales. Cuando la encarnación termina, pierdes cualquier punto de golpe temporal que te quede.
- Tu tamaño se convierte en Grande, a menos que ya fueras más grande.
- Cuando lanzas un hechizo que restaura puntos de golpe a un objetivo, otra criatura a tu elección dentro de 30 pies de ese objetivo recupera puntos de golpe igual a la mitad de la cantidad restaurada.

La encarnación persiste más allá de la transformación, pero no tiene efecto fuera de tu forma de árbol. Una vez que usas esta característica, no puedes volver a usarla hasta que completes un descanso largo.

<div class='footnote'>CLASES | DRUIDA</div>

<img src='https://hearthstone.wiki.gg/images/b/b0/The_Forest%27s_Aid_full.jpg' style='position:absolute; top:700px; right:0px; width:800px; transform:scalex(-1)' />
<img src='https://www.gmbinder.com/images/bNHsRrG.png' style='position:absolute; top:150px; right:0px; width:840px' />

\pagebreakNum

## Afinidades Salvajes
Si una afinidad salvaje tiene requisitos previos, debes cumplirlos para aprenderla. Puedes aprender la afinidad al mismo tiempo que cumples con sus requisitos previos. Un requisito de nivel se refiere a tu nivel en esta clase.

#### Hablar con Bestias
Puedes lanzar *hablar con animales* a voluntad, sin gastar un espacio de conjuro.

#### Alineación Celestial
*Requisito: nivel 5, Camino del Equilibrio*
<div style='margin-top:-6px;'></div>

Mientras estés transformado en lechúcico lunar, puedes usar cualquiera de los resultados cuando repitas la tirada de un dado de daño.

#### Transformación en Combate
Puedes transformarte como acción adicional en tu turno.

#### Cultivar
*Requisito: nivel 11, Camino de la Restauración*
<div style='margin-top:-6px;'></div>

Mientras estás transformado como un árbol, siempre que restaures puntos de golpe a una criatura, esa criatura también gana puntos de golpe temporales igual a tu modificador de Sabiduría.

#### Bestia Desplazadora
Puedes gastar un espacio de conjuro de 2.º nivel o superior para lanzar el hechizo *paso brumoso*. Al hacerlo, reapareces en un espacio desocupado como una transformación disponible de tu elección.

***Feral.*** Puedes usar esta afinidad una vez, sin gastar un espacio de conjuro. No puedes hacerlo nuevamente hasta que completes un descanso corto.

#### Impulso Felino
*Requisito: nivel 9*
<div style='margin-top:-6px;'></div>

Mientras estés transformado en forma de gato, puedes moverte a lo largo de superficies verticales en tu turno sin caer durante el movimiento. Caerás si terminas tu turno en una superficie vertical.

#### Rapidez Feral
Mientras estás transformado, puedes realizar la acción de *correr* como acción adicional. Esto no tiene efecto en forma de lechúcico o árbol.
<div style='margin-top:-1px;'></div>

#### Florecer
*Requisito: Camino de la Restauración*
<div style='margin-top:-6px;'></div>

Una vez por turno, cuando lances dados de golpe para tu característica Rejuvenecimiento, puedes repetir la tirada de uno de los dados y usar cualquiera de los resultados.
<div style='margin-top:-1px;'></div>

#### Germinación
*Requisito: nivel 7, Camino de la Restauración*
<div style='margin-top:-6px;'></div>

Siempre que uses Rejuvenecimiento, puedes gastar un espacio de conjuro de 1.º nivel o superior para elegir un segundo objetivo dentro del alcance y dividir los puntos de golpe restaurados entre los objetivos. Esto no cambia el efecto de Rejuvenecimiento.

***A niveles superiores.*** Puedes elegir un objetivo adicional por cada nivel de espacio por encima del 1.º.
<div style='margin-top:-1px;'></div>

\columnbreak

<div style='margin-top:30px;'></div>

#### Rugido
*Requisito: Camino Feral*
<div style='margin-top:-6px;'></div>

Mientras estés transformado, puedes gastar un espacio de conjuro para lanzar el hechizo *duelo obligado*.
<div style='margin-top:-1px;'></div>

#### Líder de la Manada
*Requisito: nivel 4*
<div style='margin-top:-6px;'></div>

Cualquier criatura dentro de 60 pies de ti también se ve afectada por la característica de Ritmo de Viaje de tus transformaciones siempre que no estés incapacitado.
<div style='margin-top:-1px;'></div>

#### Lluvia Lunar
*Requisito: Camino del Equilibrio, cantrip *golpe lunar*
<div style='margin-top:-6px;'></div>

Cuando golpees a un objetivo con *golpe lunar* mientras estés transformado como lechúcico lunar, la velocidad de movimiento del objetivo se reduce en 10 pies hasta el comienzo de tu próximo turno.
<div style='margin-top:-1px;'></div>

#### Marca de Ursoc
*Requisito: Camino Feral*
<div style='margin-top:-6px;'></div>

Mientras estás transformado como oso, puedes gastar un espacio de conjuro para lanzar el efecto de *agrandar* del hechizo *agrandar/reducir* sobre ti mismo. No puedes hacerlo nuevamente hasta que completes un descanso largo.
<div style='margin-top:-1px;'></div>

#### Golpe Poderoso
*Requisito: Camino Feral, nivel 5*
<div style='margin-top:-6px;'></div>

Cuando golpeas a otra criatura con un ataque de arma mientras estás transformado, puedes intentar aturdirla. El objetivo debe superar una tirada de salvación de Constitución contra la CD de salvación de tus hechizos de druida o quedará aturdido hasta el final de tu próximo turno. No puedes hacerlo nuevamente hasta que completes un descanso corto.
<div style='margin-top:-1px;'></div>

#### Nueve Vidas / Aleteo
Mientras estés transformado como gato o lechúcico lunar, puedes usar tu reacción para darte los beneficios del hechizo *caída de pluma* hasta el final de tu turno. No puedes hacerlo nuevamente hasta que completes un descanso corto.
<div style='margin-top:-1px;'></div>

#### Enfoque de la Naturaleza
*Requisito: nivel 11, Camino del Equilibrio o de la Restauración*
<div style='margin-top:-6px;'></div>

Mientras estés transformado como lechúcico lunar o árbol, sumas tu modificador de Sabiduría a cualquier tirada de salvación de Constitución que realices para mantener tu concentración.

#### Furia Primal
*Requisito: nivel 5*
<div style='margin-top:-6px;'></div>

Mientras estés transformado, tienes un bono de +1 a tus tiradas de ataque y daño con armas cuerpo a cuerpo.

<img src='https://www.gmbinder.com/images/xAAg1PL.png' style='position:absolute; top:915px; right:40px; width:350px' />

<div class='footnote'>CLASES | DRUIDA</div>

\pagebreakNum


#### Acechar
*Requisito: Camino Feral*
<div style='margin-top:-6px;'></div>

Mientras estés transformado, puedes gastar un espacio de conjuro para lanzar el hechizo *invisibilidad* sobre ti mismo. No puedes hacerlo de nuevo hasta que completes un descanso largo.

***A niveles superiores.*** Puedes elegir una criatura adicional dentro de 15 pies de ti por cada nivel del espacio de conjuro superior al 1.º.

#### Renovación
Mientras estés transformado, puedes gastar un espacio de conjuro de 1.º nivel o superior para lanzar el hechizo *curar heridas* sobre ti mismo.

***A niveles superiores.*** Cuando usas esta afinidad con un espacio de conjuro de 2.º nivel o superior, la curación aumenta en 1d8 por cada nivel del espacio superior al 1.º.

#### Golpe de Cráneo
*Requisito: nivel 5*
<div style='margin-top:-6px;'></div>

Mientras estés transformado, puedes lanzar *Contrahechizo* una vez usando un espacio de conjuro, pero solo como un hechizo de toque. No puedes hacerlo de nuevo hasta que completes un descanso largo.

#### Deriva Solar
*Requisito: Camino del Equilibrio, cantrip *ira solar*
<div style='margin-top:-6px;'></div>

Cuando lanzas *ira solar* mientras estás transformado como lechúcico lunar, el alcance del hechizo aumenta a 120 pies.

#### Rugido Estampida
Mientras estés transformado, puedes gastar un espacio de conjuro de 1.º nivel o superior y elegir cualquier número de criaturas dentro de 60 pies de ti. Cada criatura tiene su velocidad de movimiento base aumentada en 10 pies hasta el final de tu siguiente turno.

***A niveles superiores.*** La velocidad de movimiento aumenta en 10 pies por cada nivel del espacio de conjuro superior al 2.º.

\columnbreak

#### Fuego Solar
*Requisito: Camino del Equilibrio, cantrip *ira solar*
<div style='margin-top:-6px;'></div>

Cuando golpeas a un objetivo con *ira solar* mientras estás transformado como lechúcico lunar, el objetivo debe tener éxito en una tirada de salvación de Constitución contra la CD de tus hechizos o quedar cegado hasta el comienzo de tu próximo turno.

#### Instintos de Supervivencia
*Requisito: Camino Feral*
<div style='margin-top:-6px;'></div>

Mientras estés transformado como oso, cuando seas reducido a 0 puntos de golpe por un ataque o hechizo pero no seas asesinado de inmediato, puedes caer a 1 punto de golpe en su lugar. No puedes hacerlo de nuevo hasta que completes un descanso largo.

#### Piel Gruesa
*Requisito: nivel 5*
<div style='margin-top:-6px;'></div>

Mientras estés transformado, sumas +1 a tu Clase de Armadura.

#### Mente Tranquila
*Requisito: nivel 11, Camino de la Restauración*
<div style='margin-top:-6px;'></div>

Mientras estés transformado como árbol, ya no te ralentizas por *tranquilidad* y puedes usar tu movimiento completo.

#### Lunas Gemelas
*Requisito: nivel 7, Camino del Equilibrio, cantrip *golpe lunar*
<div style='margin-top:-6px;'></div>

Cuando lanzas *golpe lunar* mientras estás transformado como lechúcico lunar, puedes elegir dos objetivos, incluso si no están dentro de 5 pies uno del otro. Ambos objetivos aún deben estar dentro del alcance del hechizo.

#### Favor de Ursoc
*Requisito: Camino Feral*
<div style='margin-top:-6px;'></div>

Puedes usar la Marca de Ursoc un número de veces igual a tu modificador de Sabiduría, en lugar de dos veces. Recuperas todos los usos gastados al finalizar un descanso corto o largo.

<div class='footnote'>CLASES | DRUIDA</div>
<img src='https://www.gmbinder.com/images/958mFBu.jpg' style='position:absolute; top:630px; right:0px; width:900px' />
<img src='https://www.gmbinder.com/images/3e9S91s.png' style='position:absolute; top:-310px; right:0px; width:900px' />

\pagebreakNum

<style>.phb hr+section blockquote { background: none; border: none; box-shadow: none; } </style>

# Anexo A: Cambio de forma

___
> ## Forma Acuática
>*Tamaño Mediano*
> ___
> - **Clase de Armadura** 12 + modificador de Destreza
> - **Velocidad** 0 pies, nado 50 pies
>___
>
> ***Visión Ciega.*** Obtienes visión ciega en un radio de 60 pies.
>
> ***Ritmo de Viaje.*** Cuando viajas durante 1 hora o más, tu ritmo de viaje total se duplica (ver el capítulo 8 del *Manual del Jugador* para más información sobre el ritmo de viaje).
>
> ***Respiración Acuática.*** Solo puedes respirar bajo el agua.
>
> ### Acciones
> ***Mordisco.*** *Ataque de arma cuerpo a cuerpo:* Alcance 5 pies, un objetivo. <br> *Impacto:* (1d8 + modificador) de daño perforante.

> ##### Formas de Cambio y Modificadores de Habilidad
> Tus formas de cambio dependen de tus capacidades como druida y extraen su fuerza directamente de ti, por lo tanto, tus puntuaciones y modificadores de habilidad se utilizan cuando asumes una forma. Cuando realices una tirada de ataque en una forma, se considera que tienes competencia con el ataque y utilizas tu Fuerza o Destreza para la tirada de ataque y de daño, según se indica a continuación.
>
> Ciertas formas de cambio pueden usar tu elección de Fuerza o Destreza para sus ataques, mientras que otras dependen exclusivamente de una habilidad. Las habilidades disponibles para cada forma de cambio se enumeran a continuación.
>
> ***Acuática.*** Para alimentarse en el agua, las criaturas acuáticas deben ser fuertes, por lo que utilizas tu Fuerza para las tiradas de ataque y de daño.
>
> ***Oso.*** Los osos rugientes confían en su fuerza en combate, por lo que utilizas tu Fuerza para las tiradas de ataque y de daño.
>
> ***Gato.*** Los gatos pueden confiar tanto en la fuerza bruta como en la agilidad. Puedes usar tu elección de Fuerza o Destreza para las tiradas de ataque y de daño.
>
> ***Vuelo.*** Las aves de presa toman muchas formas. Puedes usar tu elección de Fuerza o Destreza para las tiradas de ataque y de daño.
>
> ***Lechúcico Lunar.*** Aunque rara vez lo demuestran, son criaturas poderosas, por lo que utilizas tu Fuerza para las tiradas de ataque y de daño.
>
> ***Viaje.*** Las criaturas de viaje son rápidas y fuertes, por lo que puedes usar tu elección de Fuerza o Destreza para las tiradas de ataque y de daño.
>
> ***Treant.*** Los treants errantes son lentos pero fuertes golpeadores, por lo que utilizas tu Fuerza para las tiradas de ataque y de daño.

\columnbreak

___
> ## Forma de Oso
>*Tamaño Grande*
> ___
> - **Clase de Armadura** 12 + modificador de Destreza y Constitución
> - **Velocidad** 40 pies, trepar 30 pies
> ___
>
> ***Olfato Agudo.*** Tienes ventaja en las pruebas de Sabiduría (Percepción) que dependan del olfato.
>
> ***Carga.*** Si te mueves al menos 20 pies directamente hacia un objetivo y luego realizas un ataque con arma en el mismo turno, la criatura sufre 1d8 de daño adicional. Si el objetivo es una criatura, debe tener éxito en una tirada de salvación de Fuerza (CD 8 + modificador de Fuerza + competencia). En una salvación fallida, la criatura es derribada.
>
> ### Acciones
> ***Mordisco.*** *Ataque de arma cuerpo a cuerpo:* Alcance 5 pies, un objetivo. <br> *Impacto:* (1d8 + modificador) de daño perforante.
>
> ***Garra.*** *Ataque de arma cuerpo a cuerpo:* Alcance 5 pies, un objetivo. <br> *Impacto:* (1d12 + modificador) de daño cortante.
___
> ## Forma de Gato
>*Tamaño Mediano*
> ___
> - **Clase de Armadura** 12 + modificador de Destreza
> - **Velocidad** 40 pies, trepar 40 pies
>___
>
> ***Visión en la Oscuridad.*** Obtienes visión en la oscuridad en un radio de 60 pies.
>
> ***Olfato Agudo.*** Tienes ventaja en las pruebas de Sabiduría (Percepción) que dependan del olfato.
>
> ***Embestida.*** Si te mueves al menos 20 pies directamente hacia una criatura antes de golpearla con un ataque con arma, la criatura debe tener éxito en una tirada de salvación de Fuerza (CD 8 + modificador de Destreza + competencia). En una salvación fallida, la criatura es derribada y el próximo ataque que realices antes del final de tu turno causa 2d6 de daño adicional.
>
> ***Multiataque.*** Cuando tomas la acción de Ataque para hacer un ataque con arma, puedes usar una acción adicional para atacar con un arma diferente.
>
> ### Acciones
> ***Mordisco.*** *Ataque de arma cuerpo a cuerpo:* Alcance 5 pies, un objetivo. <br> *Impacto:* (1d6 + modificador) de daño perforante.
>
> ***Garra.*** *Ataque de arma cuerpo a cuerpo:* Alcance 5 pies, un objetivo. <br> *Impacto:* (1d8 + modificador) de daño cortante.

<div class='footnote'>ANEXO A | CAMBIO DE FORMA</div>

\pagebreakNum

___
> ## Forma de Vuelo
>*Tamaño Grande*
> ___
> - **Clase de Armadura** 12 + modificador de Destreza
> - **Velocidad** 10 pies, volar 70 pies
> ___
>
> ***Vuelo Rápido.*** No provocas ataques de oportunidad cuando vuelas fuera del alcance de un enemigo.
>
> ***Vista Aguda.*** Tienes ventaja en las pruebas de Sabiduría (Percepción) que dependan de la vista.
>
> ***Ritmo de Viaje.*** Cuando viajas durante 1 hora o más, tu ritmo de viaje total se duplica (consulta el capítulo 8 del *Manual del Jugador* para más información sobre el ritmo de viaje).
>
> ### Acciones
> ***Pico.*** *Ataque de arma cuerpo a cuerpo:* Alcance 5 pies, un objetivo. <br> *Impacto:* (1d10 + modificador) de daño perforante.
>
> ***Garra.*** *Ataque de arma cuerpo a cuerpo:* Alcance 5 pies, un objetivo. <br> *Impacto:* (1d4 + modificador) de daño cortante.
___
> ## Forma de Viaje
>*Tamaño Grande*
> ___
> - **Clase de Armadura** 12 + modificador de Destreza
> - **Velocidad** 50 pies
> ___
>
> ***Montura Estable.*** Cualquier criatura montada sobre tu lomo tiene ventaja en las tiradas de salvación de Destreza para mantenerse montada.
>
> ***Ritmo de Viaje.*** Cuando viajas durante 1 hora o más, tu ritmo de viaje total se duplica (consulta el capítulo 8 del *Manual del Jugador* para más información sobre el ritmo de viaje).
>
> ### Acciones
> ***Cornada.*** *Ataque de arma cuerpo a cuerpo:* Alcance 5 pies, un objetivo. <br> *Impacto:* (1d6 + modificador) de daño cortante.
___
> ## Forma de Lechúcico Lunar
>*Tamaño Mediano*
> ___
> - **Clase de Armadura** 12 + modificador de Destreza
> - **Velocidad** 30 pies
> ___
>
> ***Visión en la Oscuridad.*** Obtienes visión en la oscuridad en un radio de 60 pies.
>
> ***Vista Aguda.*** Tienes ventaja en las pruebas de Sabiduría (Percepción) que dependan de la vista.
>
> ***Conjuración de Hechizos.*** Puedes lanzar hechizos de druida y realizar sus componentes mientras estás en esta forma. Cada vez que lances un hechizo de druida que cause daño, puedes volver a tirar un dado. Debes usar el nuevo resultado.
>
> ### Acciones
> ***Pico.*** *Ataque de arma cuerpo a cuerpo:* Alcance 5 pies, un objetivo. <br> *Impacto:* (1d6 + modificador) de daño perforante.
>
> ***Garra.*** *Ataque de arma cuerpo a cuerpo:* Alcance 5 pies, un objetivo. <br> *Impacto:* (1d4 + modificador) de daño cortante.
___
> ## Forma de Antárbol
>*Tamaño Mediano*
> ___
> - **Clase de Armadura** 12 + modificador de Destreza
> - **Velocidad** 30 pies
> ___
>
> ***Apariencia Falsa.*** Mientras permaneces inmóvil, tienes ventaja en las pruebas de Destreza (Sigilo).
>
> ***Susurro de Plantas.*** Puedes preguntar a las plantas sobre eventos ocurridos en el último día, obteniendo información sobre criaturas que hayan pasado, el clima y otras circunstancias.
>
> ***Conjuración de Hechizos.*** Puedes lanzar hechizos de druida y realizar sus componentes mientras estás en esta forma. Cuando restauras puntos de golpe a una criatura a través de un hechizo de druida y sacas un 1 natural en un dado, puedes cambiar su resultado a un 2.
>
> ### Acciones
> ***Garra.*** *Ataque de arma cuerpo a cuerpo:* Alcance 5 pies, un objetivo. <br> *Impacto:* (1d6 + modificador) de daño cortante.

<div class='footnote'>ANEXO A | CAMBIO DE FORMA</div>
<img src='https://www.gmbinder.com/images/NYEBlxm.jpg' style='position:absolute; top:750px; right:0px; width:900px' />
<img src='https://www.gmbinder.com/images/3e9S91s.png' style='position:absolute; top:-120px; right:0px; width:900px' />

\pagebreakNum

<div style='margin-top:320px'></div>

## Cazador
*El camino del cazador es uno de dominio sobre las bestias del mundo, una precisión incomparable en el manejo de armas de largo alcance y el conocimiento de cómo sobrevivir en situaciones donde otros perecerían.*

<div style="text-align:Right">

*— Guardabosques Sallina* &nbsp;</div>

De aspecto salvaje, un humano se mueve sigilosamente entre las sombras de los árboles, acechando a los orcos que planean un ataque a una granja cercana. Con una lanza en ambas manos, carga con furia, acompañado de un gran oso que ruge a su lado, cortando enemigos uno tras otro.

Evitando una ráfaga de aire helado, una elfa de la noche tensa su arco y dispara una flecha hacia un dragón azul. Resistiendo el miedo que emana del dragón, lanza flecha tras flecha, buscando los huecos entre sus escamas.

Un elfo de sangre levanta la mano y silba para llamar al halcón que vuela sobre él. Susurra instrucciones en thalassiano, señalando al oso lechuza que ha estado rastreando, y envía al halcón a distraerlo mientras prepara su arco.

### Acechadores Inescapables
Desde una edad temprana, el llamado de lo salvaje atrae a algunos aventureros fuera de la comodidad de sus hogares hacia el mundo primitivo e implacable del exterior. Aquellos que resisten se convierten en cazadores. Como maestros de su entorno, los cazadores pueden deslizarse como fantasmas entre los árboles y colocar trampas en los caminos de sus enemigos. Estos expertos tiradores derriban a sus oponentes con disparos impecables de arco, ballesta o rifle. Con la capacidad de empuñar dos armas simultáneamente, los cazadores pueden desatar una ráfaga de golpes contra cualquiera que tenga la mala suerte de entrar en combate cuerpo a cuerpo con ellos.

El arte de la supervivencia es central para la vida aislada de un cazador. Los cazadores rastrean bestias con facilidad y mejoran sus propias habilidades al sintonizarse con los aspectos ferales de varias criaturas. Son conocidos por los lazos de por vida que forman con los animales del mundo salvaje, entrenando grandes halcones, felinos, osos y muchas otras bestias para luchar a su lado.

\columnbreak

<div style='margin-top:401px;'></div>

### Orgullosos Guardabosques
El cazador es un experto en acechar en la naturaleza, sobreviviendo gracias a su conocimiento de supervivencia y habilidad con un arco o rifle. Está profundamente sintonizado con la naturaleza y cuenta con bestias poderosas como sus aliadas.

De todas las criaturas de Azeroth, pocas pueden resistirse la llamada del cazador y aún menos sobrevivir a su furia. Los cazadores, aunque tan variados como el clima, son reconocidos por su habilidad para encontrar y abatir a su presa. Muchos buscan mantener el equilibrio de la naturaleza. Aunque los guardabosques élficos dominan el terreno y prefieren el arco, los forestales optan por un enfoque más cercano, siendo hábiles en el sigilo y deslizándose por los bosques como fantasmas.

### La Elección del Cazador
Ser cazador es la elección de aquellos que rechazan las sociedades que oprimen el rol natural de presa y depredador, así como la postura druídica de solo observar la "Gran Cacería" sin participar activamente.

Llevan una vida de reverencia por la naturaleza, complementada por el uso de herramientas hechas por el hombre. Consideran natural aprovecharse de estas ventajas. Algunos prefieren un enfoque más directo al rastrear y cazar, sin depender tanto de las herramientas.

### Creación de un Cazador
Al crear a tu cazador, piensa en cómo adquiriste tus habilidades. ¿Fuiste entrenado por un solo mentor, recorriendo el desierto juntos hasta dominar los caminos del cazador? ¿Abandonaste tu entrenamiento o tu mentor fue asesinado? Tal vez adquiriste tus habilidades como parte de un grupo de cazadores afiliados a un círculo druídico, aprendiendo tanto caminos místicos como sabiduría de la naturaleza. También podrías ser autodidacta, un ermitaño que aprendió habilidades de combate, rastreo y conexión mágica con la naturaleza debido a la necesidad de sobrevivir en el desierto.

<div class='footnote'>CLASES | CAZADOR</div>
<img src='https://www.gmbinder.com/images/lz4eVfw.jpg' style='position:absolute; top:0px; right:0px; width:900px' />
<img src='https://www.gmbinder.com/images/pbSeYXZ.png' style='position:absolute; top:-250px; right:0px; width:1100px' />
<img src='https://www.gmbinder.com/images/jgUXBQo.png' style='position:absolute; top:45px; right:-75px; width:500px' />

\pagebreakNum

<div class='classTable wide'>

##### El Cazador
| Nivel | Bonificación de<br>Competencia | Marca del<br>Cazador | Dados de<br>Enfoque | Características |
|:---:|:--:|:----:|:-:|:-------------------------------------------------------|
| 1 | +2 |  1d4 | — | Marca del Cazador, Explorador Natural                        |
| 2 | +2 |  1d4 | 2 | Estilo de Combate, Enfoque, Empatía Animal                  |
| 3 | +2 |  1d4 | 3 | Arquetipo de Cazador, Domar Bestia                           |
| 4 | +2 |  1d4 | 3 | Mejora de Característica                      |
| 5 | +3 |  1d4 | 4 | Característica del Arquetipo de Cazador                     |
| 6 | +3 |  1d6 | 4 | —                                                           |
| 7 | +3 |  1d6 | 5 | Característica del Arquetipo de Cazador                     |
| 8 | +3 |  1d6 | 5 | Mejora de Característica, Pie Ligero          |
| 9 | +4 |  1d6 | 6 | —                                                           |
| 10| +4 |  1d6 | 6 | Conocimiento del Depredador                                 |
| 11| +4 |  1d8 | 7 | Característica del Arquetipo de Cazador                     |
| 12| +4 |  1d8 | 7 | Mejora de Característica                      |
| 13| +5 |  1d8 | 8 | —                                                           |
| 14| +5 |  1d8 | 8 | Acechador                                                   |
| 15| +5 |  1d8 | 8 | Característica del Arquetipo de Cazador                     |
| 16| +5 | 1d10 | 9 | Mejora de Característica                      |
| 17| +6 | 1d10 | 9 | —                                                           |
| 18| +6 | 1d10 | 9 | Sentidos Agudizados                                         |
| 19| +6 | 1d10 | 10 | Mejora de Característica                     |
| 20| +6 | 1d10 | 10 | Aspecto de lo Salvaje                                      |
</div>

&nbsp;&nbsp;&nbsp; ¿Tu carrera como aventurero es una continuación de tu trabajo protegiendo las tierras fronterizas o un cambio significativo? ¿Qué te hizo unirte a un grupo de aventureros? ¿Encuentras desafiante enseñar a tus nuevos aliados los caminos de la naturaleza o disfrutas del alivio que ofrecen a la soledad?

#### Creación Rápida
Haz que la Destreza sea tu puntuación de habilidad más alta, seguida de Sabiduría. (Algunos cazadores que se centran en el combate cuerpo a cuerpo eligen Fuerza como su puntuación más alta en lugar de Destreza).

#### Multiclase

***Caracteristica Minima.*** Debes tener al menos 13 en Fuerza o Destreza para coger un nivel en esta clase o para tomar un nivel en otra clase si ya eres un cazador.

***Competencias Ganadas.*** Armaduras ligeras, armaduras medianas, armas simples y marciales, una habilidad de la lista de habilidades de la clase.

\columnbreak

<div style='margin-top:-15px;'></div>

## Rasgos de Clase
<div style='margin-top:-5px;'></div>

#### Puntos de Golpe
___
- **Dados de Golpe:** 1d10 por nivel de cazador
- **PG al 1:** 10 + Mod. Constitución
- **PG por Nivel:** 1d10 (o 6) + Mod. Constitución por nivel de cazador
<div style='margin-top:-2px;'></div>

#### Competencias
___
- **Armadura:** Armaduras ligeras, armaduras medianas
- **Armas:** Armas simples, armas marciales, pistola, rifle
- **Herramientas:** Herramientas de armero
- **Tiradas de Salvación:** Fuerza, Destreza
- **Habilidades:** Elige tres entre Trato con Animales, Perspicacia, Investigación, Naturaleza, Percepción, Sigilo y Supervivencia
<div style='margin-top:-2px;'></div>

#### Equipo
Comienzas con el siguiente equipo, además del equipo otorgado por tu trasfondo:
 - *(a)* cota de escamas o *(b)* armadura de cuero
 - *(a)* dos espadas cortas o *(b)* un arma marcial cuerpo a cuerpo
 - *(a)* un paquete de aventurero o *(b)* un paquete de explorador
 - *(a)* una ballesta ligera y 20 virotes, *(b)* un arco largo y carcaj con 20 flechas, o *(c)* un rifle y 20 balas
 - Herramientas de armero y una trampa de caza

<div class='footnote'>CLASES | CAZADOR</div>

\pagebreakNum

### Marca del Cazador
A partir del 1er nivel, puedes marcar a un objetivo como tu presa. Como acción adicional, elige una criatura que puedas ver a 120 pies de distancia. El objetivo permanece marcado durante 1 hora, hasta que uses esta característica nuevamente o hasta que muera. La marca también termina si caes inconsciente.

Una vez por turno, puedes infligir un daño adicional de 1d4 a esa criatura cuando la golpeas con un ataque con arma. La cantidad de daño adicional aumenta a medida que subes de nivel en esta clase, como se muestra en la columna Marca del Cazador de la tabla de Cazador.

Además, tienes ventaja en las pruebas de Sabiduría (Percepción) y Sabiduría (Supervivencia) para encontrar a tu objetivo marcado.

### Explorador Natural
En el 1er nivel, eres hábil para moverte por el mundo natural y reaccionas con rapidez y decisión cuando te atacan. Ganas los siguientes beneficios:
 - Añades tu modificador de Sabiduría a tus tiradas de iniciativa.
 - En tu primer turno durante el combate, tienes ventaja en las tiradas de ataque contra criaturas que no hayan actuado todavía.

Además, eres experto en recorrer la naturaleza y obtienes los siguientes beneficios cuando viajas durante una hora o más:
 - Tienes ventaja en las pruebas para evitar perderte.
 - Tienes ventaja en las pruebas de Sabiduría (Supervivencia) que hagas para buscar comida.
 - Incluso cuando estés realizando otra actividad mientras viajas (como buscar comida, navegar o rastrear), permaneces alerta al peligro.
 - Si viajas solo o solo con tu compañero bestia, puedes moverte sigilosamente a un ritmo normal.
 - Mientras rastreas otras criaturas, también aprendes su número exacto, sus tamaños y cuánto tiempo ha pasado desde que pasaron por el área.

### Estilo de Combate
En el 2º nivel, adoptas un estilo de combate específico como tu especialidad. Elige una de las siguientes opciones. No puedes elegir un estilo de combate más de una vez, incluso si tienes la opción de elegir nuevamente.

#### Tiro con Arco
Obtienes un bonificador de +2 a las tiradas de ataque que hagas con armas a distancia.

#### Tirador en Combate Cercano
Cuando realizas un ataque a distancia mientras estás a 5 pies de una criatura hostil, no tienes desventaja en la tirada de ataque. Tus ataques a distancia ignoran media cobertura y tres cuartos de cobertura contra objetivos a 30 pies de ti. Finalmente, tienes un bonificador de +1 a las tiradas de ataque con armas a distancia.

#### Combate con Dos Armas
Cuando te involucras en combate con dos armas, puedes añadir tu modificador de habilidad al daño del segundo ataque.

\columnbreak

#### Combate con Arma Grande
Cuando sacas un 1 o un 2 en un dado de daño para un ataque que haces con un arma cuerpo a cuerpo que estás empuñando con dos manos, puedes volver a tirar el dado y debes usar el nuevo resultado, incluso si es un 1 o un 2. El arma debe tener la propiedad de dos manos o versátil para que puedas usar este beneficio.

### Enfoque
A partir del 2º nivel, tu enfoque como cazador te diferencia de los rastreadores y exploradores comunes, dándote acceso a un grupo de dados de enfoque, que son d8. Tu nivel de cazador determina la cantidad de dados que tienes, como se muestra en la columna Dados de Enfoque de la tabla de Cazador.

Puedes usar estos dados para obtener diferentes beneficios. Conoces tres beneficios: Llamada de lo Salvaje, Ataque Preciso y Tácticas de Supervivencia. Un dado de enfoque se gasta cuando lo usas. Recuperas todos los dados de enfoque gastados cuando terminas un descanso corto o largo.

#### Llamada de lo Salvaje
Cuando hagas una prueba que te permita aplicar tu competencia en Naturaleza, Percepción o Supervivencia, puedes gastar un dado de enfoque para reforzar la prueba. Añade la mitad del número obtenido en el dado de enfoque (redondeado hacia arriba) a tu prueba. Aplicas este bonificador después de hacer la prueba, pero antes de saber si fue exitosa.

#### Ataque Preciso
Cuando haces un ataque con arma contra una criatura, puedes gastar un dado de enfoque para añadirlo a la tirada de ataque. Puedes usar esta habilidad antes o después de hacer la tirada de ataque, pero antes de que se apliquen los efectos del ataque.

#### Tácticas de Supervivencia
Si eres golpeado por un ataque mientras llevas puesta armadura ligera o media, puedes gastar un dado de enfoque como reacción y añadir el número obtenido a tu CA. Si el ataque aún golpea, recibes la mitad del daño.

### Empatía Animal
También en el 2º nivel, tu dominio del conocimiento de cazador te permite establecer un vínculo poderoso con las bestias y el entorno que te rodea.

Tienes la habilidad innata de comunicarte con las bestias, y estas te reconocen como un espíritu afín. Mediante sonidos y gestos, puedes comunicar ideas simples a una bestia como acción, y puedes leer su estado de ánimo e intención básica. Aprendes su estado emocional, si está afectada por algún tipo de magia, sus necesidades a corto plazo (como comida o seguridad) y acciones que puedes realizar (si las hay) para persuadirla de que no ataque.

No puedes usar esta habilidad contra una criatura que hayas atacado en las últimas 24 horas.

<div class='footnote'>CLASES | CAZADOR</div>

\pagebreakNum

### Arquetipo de Cazador
En el 3er nivel, eliges seguir el camino de un arquetipo de cazador: Maestro de Bestias, Puntería o Supervivencia, cada uno de ellos detallado al final de la descripción de la clase.

Tu elección te otorga características en el 3er nivel y nuevamente en el 5º, 7º, 11º y 15º nivel.

### Domar Bestia
A partir del 3er nivel, muestras una conexión fortalecida con la naturaleza y eres capaz de crear un poderoso vínculo con una criatura del mundo natural.

Puedes intentar domar a una bestia que esté a 60 pies de ti y que pueda verte y oírte; la bestia no puede ser más grande que Mediana y debe tener un valor de desafío de 1/2 o menor. Domar a una bestia requiere gastar 50 po en hierbas raras y comida fina, y es un proceso que a menudo lleva muchas horas de trabajo o días (a discreción del DM).

Una vez que domas a una bestia, gana todos los beneficios de tu habilidad de Vínculo de Compañero. Solo puedes tener una bestia domesticada a tu lado a la vez.

#### Vínculo del Compañero
Tu leal compañero gana una variedad de beneficios.

- La bestia pierde su acción de Multiataque, si tiene una.
- Tu compañero obedece tus órdenes lo mejor que puede. Comparte tu conteo de iniciativa, pero actúa inmediatamente después de ti. Puede moverse y usar su reacción por sí solo, pero la única acción que realiza es la acción de Esquivar, a menos que uses tu acción adicional para ordenarle que realice la acción de Atacar, Correr, Desengancharse o Ayudar. Si estás incapacitado o ausente, tu bestia actúa por su cuenta.
- Tu compañero bestial tiene habilidades y estadísticas determinadas en parte por tu nivel, usando tu bonificador de competencia en lugar del suyo. Además de las áreas donde normalmente usa su bonificador de competencia, tu compañero también agrega su bonificador de competencia a su CA y a sus tiradas de daño.
- Tu bestia gana competencia en dos habilidades de tu elección. También se vuelve competente en todas las tiradas de salvación.
- Por cada nivel de personaje que ganes después del 3º, tu compañero bestial gana un dado de golpe adicional y aumenta sus puntos de golpe en consecuencia.
- Siempre que obtengas una mejora de característica de habilidad (*Ability Score Improvement*), las habilidades de tu compañero también mejoran. Tu compañero puede aumentar un puntaje de habilidad de tu elección en 2, o puede aumentar dos puntajes de habilidad de tu elección en 1. Como es normal, tu compañero no puede aumentar un puntaje de habilidad por encima de 20 usando esta característica.
- La alineación de tu compañero cambia para compartir la tuya.

\columnbreak

### Mejora de Caracteristica
Cuando alcanzas el 4º nivel, y nuevamente en el 8º, 12º, 16º y 19º nivel, puedes aumentar una puntuación de caracteristica de tu elección en 2, o puedes aumentar dos puntuaciones de caracteristica de tu elección en 1. Como es normal, no puedes aumentar una puntuación de caracteristica por encima de 20 usando esta característica.

### Pie Veloz
A partir del 8º nivel, puedes realizar la acción de Correr como una acción adicional en tu turno.

Además, puedes pasar a través de plantas no mágicas sin que te ralenticen ni te causen daño si tienen espinas, púas u otros peligros similares.

### Conocimiento del Depredador
En el 10º nivel, puedes obtener un conocimiento íntimo de las capacidades de tu objetivo marcado. Puedes usar tu acción para aprender dos de las siguientes características de tu elección sobre el objetivo de tu marca de cazador si está dentro de 120 pies.
- Tipo de Criatura
- Clase de Armadura
- Velocidad
- Vulnerabilidades al Daño
- Resistencias al Daño
- Inmunidades al Daño
- Sentidos

Una vez que hayas obtenido las capacidades de una criatura, no puedes usar *Conocimiento del Depredador* para aprender más sobre la criatura, o sobre otra criatura similar, durante las siguientes 24 horas.

### Acechador
A partir del 14º nivel, puedes usar la acción de Esconderse como una acción adicional en tu turno. Además, no puedes ser rastreado por medios no mágicos, a menos que elijas dejar un rastro.

### Sentidos Aguzados
A partir del 18º nivel, obtienes sentidos sobrenaturales que te ayudan a luchar contra criaturas que no puedes ver. Cuando atacas a una criatura que no puedes ver, tu incapacidad para verla no impone desventaja en tus tiradas de ataque contra ella.

También eres consciente de la ubicación de cualquier criatura invisible dentro de 30 pies de ti, siempre que la criatura no esté escondida de ti y no estés cegado o ensordecido.

### Aspecto de lo Salvaje
En el 20º nivel, te conviertes en un cazador incomparable. Una vez en cada uno de tus turnos, puedes añadir tu modificador de Sabiduría a la tirada de ataque o a la tirada de daño de un ataque que realices. Puedes elegir usar esta característica antes o después de la tirada, pero antes de que se apliquen los efectos de la tirada.

<div class='footnote'>CLASES | CAZADOR</div>

\pagebreakNum


## Arquetipos de Cazador
Todos los cazadores tienen ciertas cosas en común, como su amor por la naturaleza o su pasión por las bestias. Pero algunos cazadores tienen un amor especial por las bestias, mientras que otros tienen un mayor amor por la naturaleza. Los cazadores se dividen en tres categorías: Maestro de Bestias, Puntería y Supervivencia.

### Maestro de Bestias
Entre los cazadores dotados, hay quienes se sienten atraídos por las bestias de la naturaleza y buscan establecer un vínculo con estas criaturas. Los maestros de bestias a menudo son atraídos hacia el mundo primitivo, vigorizados por su naturaleza peligrosa e indómita. El mundo primitivo se convierte en su hogar y sus feroces depredadores se convierten en su familia.

#### Domador de Bestias
A partir del momento en que eliges este arquetipo en el nivel 3, muestras una habilidad excepcional al tratar con bestias y puedes domar bestias que sean Grandes o más pequeñas con un valor de desafío de 1 o menor.

#### Aspecto de la Bestia
Al nivel 3, obtienes la habilidad de lanzar el conjuro *Sentido de bestia*, pero solo como un ritual y solo en tu mascota.

#### Comando de Matar
Al nivel 5, tú y tu mascota formáis un equipo de combate más efectivo. Puedes usar tu acción adicional y gastar un dado de enfoque para dar una orden de "matar" a tu mascota. La bestia realiza la acción de Atacar, realizando todos los ataques con ventaja. Añades el dado de enfoque a la tirada de daño del primer ataque que acierte.

#### Maniobra Evasiva
A partir del 7º nivel, cuando tú o tu compañero bestial estén sujetos a un efecto que permita realizar una tirada de salvación de Destreza para recibir solo la mitad del daño, puedes usar tu reacción para que ambos eviten la mayor parte del efecto.

No recibes daño si tienes éxito en la tirada de salvación, y solo la mitad del daño si fallas. Tu compañero bestial debe poder oírte y tú debes poder verlo para que se beneficie de tu característica de *Maniobra Evasiva*.

#### Furia Bestial
A partir del nivel 11, tu mascota puede atacar dos veces, en lugar de una -- o usar su Multiataque, siempre que uses tu acción adicional para ordenarle que realice la acción de Atacar.

#### Espíritu Afín
Al nivel 15, el llamado de tu mascota puede mantenerte luchando y superar heridas graves. Cuando recibas daño que te reduzca a 0 puntos de golpe pero no te mate al instante, tu compañero bestial puede usar su reacción para llamarte. <br> Si puedes ver u oír su llamado, inmediatamente recuperas puntos de golpe igual a tu nivel de cazador y permaneces consciente.

Una vez que tú (y tu mascota) uses esta característica, no podrás volver a usarla hasta que termines un descanso largo.

### Puntería
Los cazadores de puntería prefieren el uso de armas que son más mortíferas a gran distancia. Muchos cazadores de puntería descuidan la compañía de una bestia, enfocándose únicamente en su propia destreza. Se ocultan de su objetivo y lanzan sus disparos hacia presas desprevenidas.

#### Disparo Arcano
A partir del momento en que eliges este arquetipo en el 3er nivel, puedes evocar energía arcana en tus ataques. Cuando realices la acción de Ataque, puedes elegir realizar tus ataques con armas a distancia contra tu criatura marcada como Disparos Arcanos. Hasta el final de tu turno, tus ataques a distancia contra tu objetivo marcado obtienen los siguientes beneficios:

- Tus ataques ignoran la mitad y tres cuartos de cobertura.
- En cada impacto, el arma inflige daño de fuerza adicional al objetivo igual a 2 + la mitad de tu nivel de cazador.

Puedes usar esta característica un número de veces igual a tu modificador de Sabiduría. Recuperas todos los usos gastados al finalizar un descanso corto o largo.

#### Lobo Solitario: Ataque Apuntado
También en el nivel 3, puedes elegir no domar una bestia y en su lugar enfocarte en tu propia destreza. Cuando no tienes la lealtad de un compañero bestial, puedes usar tu acción adicional para otorgar ventaja a tu próximo ataque con arma.

#### Disparo Conmocionante
A partir del nivel 5, cuando golpees a un objetivo con un ataque que lo obligue a realizar una tirada de salvación de Constitución para mantener la concentración, puedes gastar un dado de enfoque y añadirlo a la clase de dificultad. Debes hacerlo antes de que el objetivo haga la tirada.

#### Lobo Solitario: Ataque Adicional
También en el nivel 5, cuando no tienes un compañero animal, obtienes Ataque Adicional y puedes atacar dos veces, en lugar de una, siempre que realices la acción de Ataque en tu turno.

#### Aspecto del Aguila
A partir del nivel 7, puedes ver hasta 1 milla de distancia sin dificultad, pudiendo discernir incluso los detalles más finos como si estuvieras observando algo a no más de 30 metros de distancia.

Además, atacar a larga distancia no impone desventaja en tus tiradas de ataque con armas a distancia.

<div class='footnote'>CLASES | CAZADOR</div>

\pagebreakNum


#### Ataque Múltiple
Al alcanzar el nivel 11, obtienes una de las siguientes características de tu elección.

***Disparo de Quimera.*** Una vez en cada uno de tus turnos, cuando hagas un ataque con arma a distancia, puedes realizar otro ataque con la misma arma contra una criatura diferente que esté a 5 pies del objetivo original y dentro del alcance de tu arma. Si se usa con tu característica Lobo Solitario, ambos ataques tienen ventaja.

***Disparo Penetrante.*** Una vez en cada uno de tus turnos, cuando realices un ataque con arma a distancia contra una criatura, puedes hacer que el ataque atraviese múltiples criaturas. Realiza una tirada de ataque con desventaja contra cada criatura en una línea directamente detrás del objetivo original, hasta que falles, golpees un objeto o alcances el rango normal de tu arma, lo que ocurra primero.

Los ataques penetrantes no se benefician de efectos que te otorguen ventaja o cancelen la desventaja. Sin embargo, si se usa con tu característica Lobo Solitario: Ataque Apuntado, los ataques ya no se realizan con desventaja.

#### Enfoque del Tirador
En el nivel 15, cuando lances iniciativa y no tengas usos restantes de Disparo Arcano, recuperas un uso.

### Supervivencia
Para algunos cazadores, el llamado de lo salvaje es todo lo que importa. Vivir y respirar entre su flora y fauna, convirtiéndose en un reflejo de su entorno implacable. Estos cazadores astutos prefieren su ingenio y conocimiento de la tierra sobre la fuerza bruta de su compañero o su puntería a distancia.

#### Trampero Experto
A partir del momento en que eliges este arquetipo en el 3er nivel, aprendes a colocar y a infundir trampas con el vigor de la naturaleza.

***Trampas Conocidas.*** Aprendes dos trampas de tu elección, que se detallan en la sección de "trampas".

Aprendes una trampa adicional de tu elección en los niveles 7, 11 y 15. Cada vez que aprendas nuevas trampas, también puedes reemplazar una trampa que conoces con una diferente.

***Colocar una Trampa.*** Puedes usar tu acción y gastar un uso de esta característica para colocar una trampa en un espacio vacío a 30 pies de ti. Una trampa dura 1 hora, hasta que se active o hasta que la recuperes.

Una criatura que se acerque a tu trampa debe superar una prueba de Sabiduría (Percepción) o Inteligencia (Investigación) contra tu CD de salvación de trampa para notarla. Una criatura supera automáticamente la prueba si te vio colocar la trampa.

Puedes colocar dos trampas entre descansos. Recuperas todos los usos de trampa gastados al finalizar un descanso corto o largo. <br> En el nivel 11, puedes colocar tres trampas entre descansos.

***Activar una Trampa.*** Una trampa tiene un alcance de 5 pies. Cuando una criatura que no seas tú o tu compañero bestial entra en el alcance de la trampa o comienza su turno allí, la trampa se activa y se destruye.

***Desactivar una Trampa.*** Puedes recuperar una trampa colocada que no haya sido activada usando una acción mientras estés a 5 pies de ella, recuperando un uso gastado de esta característica.

***Tiradas de Salvación.*** Tus trampas requieren que el objetivo realice una tirada de salvación para resistir su efecto. La CD de salvación de tus trampas se calcula de la siguiente manera:

<div style="text-align: Center">

**CD de salvación de Trampa** = <br>8 + Bonus competencia + Mod. Sabiduría
</div>

#### Estudiante de lo Salvaje
En el nivel 3, obtienes competencia en supervivencia si aún no la tienes, y tu bonificador de competencia se duplica para cualquier prueba de habilidad que hagas con ella.

#### Lobo Solitario: Nacido para ser Salvaje
También en el nivel 3, puedes elegir no domar una bestia y, en cambio, enfocarte en tu propia destreza. Cuando no tienes la lealtad de un compañero bestial, tus ataques con armas marcan un golpe crítico en una tirada de 19 o 20. También puedes realizar la acción de Desengancharte como una acción adicional.

#### Corte de Ala
A partir del nivel 5, cuando golpeas a un objetivo con un ataque con arma, puedes gastar un dado de enfoque para intentar dificultar su movimiento. El objetivo debe tener éxito en una prueba de Fuerza (Atletismo) (CD igual a tu CD de Trampa + tu dado de enfoque) o su velocidad se reduce a 0 hasta el inicio de tu próximo turno.

#### Lobo Solitario: Ataque Adicional
También en el nivel 5, cuando no tienes la lealtad de un compañero bestial, obtienes la característica de Ataque Adicional, y puedes atacar dos veces, en lugar de una, siempre que realices la acción de Ataque en tu turno.

#### Camuflaje Natural
A partir del nivel 7, obtienes la capacidad de lanzar el conjuro *pasar sin dejar rastro* sin proporcionar componentes materiales, pero solo como un ritual. Debes tener acceso a barro fresco, tierra, plantas, hollín u otros materiales naturales para poder hacerlo.

#### Contraataque Marcado
Al alcanzar el nivel 11, si tu objetivo marcado te obliga a realizar una tirada de salvación, puedes usar tu reacción para realizar un ataque con arma contra el objetivo. Realizas este ataque antes de hacer la tirada de salvación. Si tu ataque impacta, obtienes ventaja en tu tirada de salvación, además de los efectos normales del ataque.

#### Términos de Compromiso
En el nivel 15, demuestras un control incomparable sobre tus trampas y utilizas las oportunidades que crean.

Obtienes los siguientes beneficios:
- Tienes ventaja en ataques con armas contra cualquier criatura que haya sido golpeada por una de tus trampas desde el final de tu último turno.
- Tus trampas ya no se activan cuando una criatura entra en su alcance; en su lugar, puedes elegir como acción gratuita activar una trampa, incluso si no hay una criatura cerca.


<div class='footnote'>CLASES | CAZADOR</div>

\pagebreakNum

#### Trampas
Las trampas se presentan en orden alfabético.

***Trampa de Oso.*** Cuando se activa la trampa, cada criatura en su alcance debe tener éxito en una tirada de salvación de Destreza o ser derribada y quedar boca abajo en su espacio. Cualquier criatura derribada por esta trampa tiene su velocidad reducida a 0 hasta el inicio de su siguiente turno.

***Trampa Cegadora.*** Cuando se activa la trampa, cada criatura en su alcance debe realizar una tirada de salvación de Constitución. En una tirada fallida, el objetivo queda cegado hasta el inicio de su siguiente turno.

Cualquier criatura invisible que falle esta tirada brilla con luz tenue, haciéndola visible por la duración.

***Trampa Enredadora.*** Cuando se activa la trampa, cada criatura en su alcance debe tener éxito en una tirada de salvación de Fuerza o quedar restringida durante 1 minuto. Una criatura restringida por esta trampa puede usar su acción para realizar una prueba de Fuerza contra tu CD de Trampa. En un éxito, se libera.

***Trampa Explosiva.*** Cuando se activa la trampa, cada criatura en su alcance debe realizar una tirada de salvación de Destreza, recibiendo daño por fuego igual al doble de tu nivel de cazador en una tirada fallida, o la mitad de ese daño en una exitosa.

\columnbreak

***Trampa de Congelación.*** Cuando se activa la trampa, la criatura que la activó debe realizar una tirada de salvación de Destreza o quedar restringida durante 1 minuto. Mientras esté restringida, la criatura tiene cobertura total y no puede realizar ninguna acción, salvo intentar liberarse realizando una prueba de Fuerza contra tu CD de Trampa. En un éxito, rompe el hielo y se libera. Esta trampa no tiene efecto en criaturas de tamaño Enorme o mayores.

La criatura está encerrada en hielo; el hielo tiene una CA de 10 y puntos de golpe igual a cuatro veces tu nivel de cazador.

***Trampa de Hielo.*** Cuando se activa la trampa, el hielo se extiende en un radio de 20 pies alrededor de la trampa, creando un terreno difícil. Una criatura que comience su turno o se mueva a través del área por primera vez en su turno debe realizar una tirada de salvación de Destreza o caer boca abajo.

***Trampa de Inmolación.*** Cuando se activa la trampa, cada criatura en su alcance debe realizar una tirada de salvación de Destreza, recibiendo daño por fuego igual a tu nivel de cazador en una tirada fallida, o la mitad en una exitosa. En una tirada fallida, la criatura recibe daño igual a la mitad de tu nivel de cazador (redondeado hacia arriba) al inicio de cada uno de sus turnos hasta que las llamas sean apagadas como una acción.

***Trampa de Veneno.*** Cuando se activa la trampa, cada criatura en su alcance recibe 1 punto de daño perforante y debe tener éxito en una tirada de salvación de Constitución. En una tirada fallida, la criatura queda envenenada durante 1 minuto. La criatura puede repetir la tirada de salvación al final de cada uno de sus turnos. En un éxito, la condición de envenenado desaparece.

<div class='footnote'>CLASES | CAZADOR</div>
<img src='https://www.gmbinder.com/images/zivJGbT.jpg' style='position:absolute; top:700px; right:0px; width:800px;' />
<img src='https://www.gmbinder.com/images/bNHsRrG.png' style='position:absolute; top:-98px; right:0px; width:1000px' />

\pagebreakNum

<div style='margin-top:545px'></div>

## Mago
*Recuerda siempre que el poder es una espada de doble filo. Un lado luminoso, el otro oscuro. Te llama cuando estás más desesperado; cuando la victoria parece valer cualquier sacrificio. Hay un precio que pagar por tal regalo, y muchos aceptan ansiosamente el trato. No hay que temer al poder en sí mismo. Teme, en cambio, a quienes lo empuñan.*  
<div style="text-align:Right">

*— Jaina Valiente* <br/>  </div> 

Vestida con una túnica dorada, una elfa de sangre cierra los ojos para bloquear las distracciones del campo de batalla y canta en silencio. Con movimientos ágiles de sus dedos, lanza una perla de fuego hacia las filas enemigas, que estalla en una conflagración abrasadora.

El aire vibra mientras un draenei levanta las manos, torciendo el aire a su alrededor. Una barrera de fuerza lo envuelve, bloqueando una lluvia de ataques.

Con ojos brillantes, un humano pisa fuerte el suelo, desatando llamas abrasadoras a su alrededor mientras sus enemigos lo atacan. Un torrente de fuego infernal envuelve a sus agresores.

Los magos son los supremos usuarios de la magia, definidos y unidos por los hechizos que lanzan. Extraen poder de las líneas de ley que impregnan Azeroth, lanzando conjuros explosivos, relámpagos y artes engañosas. Su magia convoca monstruos de otros planos, vislumbra el futuro, transforma sustancias, invoca meteoros o abre portales a través de continentes.

\columnbreak

<div style='margin-top:317px'></div>

### Maestros del Tiempo y el Espacio
Los estudiantes dotados de una aguda inteligencia y una disciplina inquebrantable pueden caminar el camino del mago. La magia arcana a disposición de los magos es tanto poderosa como peligrosa, y por eso solo se revela a los practicantes más dedicados. 

Para evitar interferencias en su lanzamiento de hechizos, los magos solo usan armaduras de tela, aunque escudos arcanos y encantamientos les brindan protección adicional. Desde lejos, invocan estallidos de fuego capaces de arrasar campos enteros y desatan tormentas de nieve que rompen huesos.

Los más poderosos entre ellos pueden incluso generar mejoras y portales, ayudando a sus aliados mediante el fortalecimiento de sus mentes o transportándolos instantáneamente a través del mundo.

### Eruditos de lo Arcano
Salvaje y enigmática, variada en forma y función, la magia atrae a estudiantes que buscan dominar sus misterios. Algunos aspiran a convertirse en titanes, moldeando la realidad misma. Aunque lanzar un hechizo típico solo requiere pronunciar unas pocas palabras extrañas, realizar gestos efímeros y a veces emplear materiales exóticos, estos componentes apenas insinúan la experiencia adquirida tras años de aprendizaje y estudios interminables.

### La Atracción del Conocimiento
La vida de los magos rara vez es mundana. Lo más cercano a una vida ordinaria que un mago podría experimentar es trabajar como sabio o conferenciante en una biblioteca o universidad, enseñando a otros los secretos del multiverso. Pero la atracción del conocimiento y el poder llama incluso a los magos menos aventureros, llevándolos a ruinas olvidadas y ciudades perdidas.

### Creando un Mago
Crear un personaje mago requiere una historia de fondo marcada por al menos un evento extraordinario. ¿Cómo descubriste tu aptitud para la magia? ¿Tenías un talento natural o fuiste el diligente aprendiz de otro mago? ¿O acaso te encontraste con una criatura mágica o un viejo tomo lleno de secretos arcanos?

¿Qué te llevó entonces a aventurarte? ¿Descubriste un tesoro de conjuros y poder perdido hace siglos, o estás buscando un conocimiento que ningún libro puede enseñar?

<div class='footnote'>CLASES | MAGO</div>
<img src='https://www.gmbinder.com/images/4bKo7jE.jpg' style='position:absolute; top:-200px; right:-150px; width:1000px' />
<img src='https://www.gmbinder.com/images/vn90cy3.png' style='position:absolute; top:-300px; right:0px; width:1100px' />
<img src='https://www.gmbinder.com/images/dYHZ0Ix.png' style='position:absolute; top:30px; right:325px; width:650px' />

\pagebreakNum

<div class='classTable wide'>

##### El Mago
| Nivel | Bonus de<br/>Competencia | Puntos de<br/>Hechicería | | Características | Trucos<br/>Conocidos | |1º| |2º| |3º| |4º| |5º| |6º| |7º| |8º| |9º <div style="position: absolute; top:90px; right:70px; width:200px; height:25px">—Espacios de Conjuros por Nivel—</div>|
|:---:|:--:|:-:|-|:----------|:-:|-|:-:|-|:-:|-|:-:|-|:-:|-|:-:|-|:-:|-|:-:|-|:-:|-|:-:|
| 1 | +2 | —|| Lanzamiento de Conjuros, Sentido Mágico                              |3||2||—||—||—||—||—||—||—||—|
| 2 | +2 | 2|| Fuente de Magia, Estudio Mágico                           |3||3||—||—||—||—||—||—||—||—|
| 3 | +2 | 3|| Metamagia, Fórmulas de Cantrips                                              |3||4||2||—||—||—||—||—||—||—|
| 4 | +2 | 4|| Mejora de Característica                             |4||4||3||—||—||—||—||—||—||—|
| 5 | +3 | 5|| —                                                      |4||4||3||2||—||—||—||—||—||—|
| 6 | +3 | 6|| Característica de Estudio Mágico                                  |4||4||3||3||—||—||—||—||—||—|
| 7 | +3 | 7|| —                                                      |4||4||3||3||1||—||—||—||—||—|
| 8 | +3 | 8|| Mejora de Característica                              |4||4||3||3||2||—||—||—||—||—|
| 9 | +4 | 9|| —                                                      |4||4||3||3||3||1||—||—||—||—|
| 10| +4 |10|| Característica de Estudio Mágico, Metamagia                      |4||4||3||3||3||2||—||—||—||—|
| 11| +4 |11|| —                                                      |5||4||3||3||3||2||1||—||—||—|
| 12| +4 |12|| Mejora de Característica                              |5||4||3||3||3||2||1||—||—||—|
| 13| +5 |13|| —                                                      |5||4||3||3||3||2||1||1||—||—|
| 14| +5 |14|| Característica de Estudio Mágico                                  |5||4||3||3||3||2||1||1||—||—|
| 15| +5 |15|| —                                                      |5||4||3||3||3||2||1||1||1||—|
| 16| +5 |16|| Mejora de Característica                              |5||4||3||3||3||2||1||1||1||—|
| 17| +6 |17|| Metamagia                                             |5||4||3||3||3||2||1||1||1||1|
| 18| +6 |18|| Maestría de Hechizos                                          |5||4||3||3||3||3||1||1||1||1|
| 19| +6 |19|| Mejora de Característica                              |5||4||3||3||3||3||2||1||1||1|
| 20| +6 |20|| Hechizo Emblemático                                        |5||4||3||3||3||3||2||2||1||1|
</div>

#### Multiclase

***Caracteristica Minima.*** Debes tener al menos un 13 de Inteligencia para coger un nivel en esta clase, o para coger un nivel en otra clase si ya eres un mago.

***Competencias Obtenidas.*** No recibes competencias adicionales al tomar un nivel en mago si esta no es tu clase inicial.

***Espacios de Conjuros.*** Suma tus niveles en la clase de mago a los niveles apropiados de otras clases para determinar tus espacios de conjuros disponibles.

#### Creación Rápida
Haz que tu caracteristica principal sea Inteligencia, seguida de Constitución o Destreza. Elige el trasfondo de sabio.

Despues elige los trucos *luz* y *mano de mago*, así como otro truco adicional, junto con los siguientes conjuros de nivel 1 para tu libro de conjuros: *manos ardientes*, *detectar magia*, *caída de pluma*, *rayo escarchante*, *armadura de mago* y *proyectil mágico*.

\columnbreak

## Rasgos de Clase

#### Puntos de Golpe
___
- **Dados de Golpe:** 1d6 por nivel de mago
- **PG al Nivel 1:** 6 + Mod. Constitución
- **PG por nivel:** 1d6 (o 4) + Mod. Constitución por nivel de mago después del 1
___

#### Competencias
___
- **Armadura:** Ninguna
- **Armas:** Armas simples
- **Herramientas:** Ninguna
- **Tiradas de Salvación:** Inteligencia, Sabiduría
- **Habilidades:** Elige dos entre Arcana, Historia, Perspicacia, Investigación, Medicina y Religión

#### Equipo
Empiezas con el siguiente equipo, además del equipo concedido por tu trasfondo:
 - *(a)* un bastón o *(b)* una daga
 - *(a)* una bolsa de componentes o *(b)* un foco arcano
 - *(a)* un paquete de erudito o *(b)* un paquete de explorador
 - Un libro de conjuros

<div class='footnote'>CLASES | MAGO</div>

\pagebreakNum

### Lanzamiento de Conjuros
*Característica de mago de 1er nivel*  
<div style='margin-top:-4px'></div>

Como estudiante de lo arcano, posees un libro de conjuros con hechizos que muestran los destellos de tu verdadero poder. Consulta el capítulo 10 del *Manual del Jugador* para conocer las reglas generales del lanzamiento de conjuros y el capítulo 6 de este libro para la lista de conjuros del mago.

#### Trucos
Al nivel 1, aprendes tres trucos de tu elección de la lista de conjuros de mago. Aprendes cantrips adicionales de tu elección a niveles superiores, como se muestra en la columna de Conjuros Conocidos de la tabla de mago.

<div style='margin-top:20px;'></div>

> ##### Tu Libro de Conjuros
> Los conjuros que agregas a tu libro reflejan tanto la investigación arcana que realizas como tus avances intelectuales sobre la naturaleza del multiverso. También puedes encontrar otros conjuros durante tus aventuras, por ejemplo, al descubrir un pergamino en el cofre de un hechicero malvado o un tomo polvoriento en una antigua biblioteca.
>
> ***Copiar un Conjuro al Libro.*** Cuando encuentras un conjuro de mago de 1er nivel o superior, puedes agregarlo a tu libro de conjuros si es de un nivel que puedes preparar y si puedes dedicar tiempo a descifrarlo y copiarlo.
>
> Copiar un conjuro en tu libro implica reproducir la forma básica del conjuro, luego descifrar el sistema único de notación usado por el mago que lo escribió. Debes practicar el conjuro hasta que comprendas los sonidos o gestos requeridos y luego transcribirlo en tu libro de conjuros usando tu propia notación.
>
> Por cada nivel del conjuro, el proceso toma 2 horas y cuesta 50 po. El costo representa los componentes materiales que gastas mientras experimentas con el conjuro para dominarlo, así como las tintas que necesitas para registrarlo. Una vez que has gastado este tiempo y dinero, puedes preparar el conjuro como cualquier otro.
>
> ***Reemplazar el Libro.*** Puedes copiar un conjuro de tu propio libro en otro libro, por ejemplo, si quieres hacer una copia de respaldo de tu libro de conjuros. Esto es como copiar un nuevo conjuro en tu libro, pero más rápido y fácil, ya que comprendes tu propia notación y ya sabes cómo lanzar el conjuro. Solo necesitas gastar 1 hora y 10 po por cada nivel del conjuro copiado.
>
> Si pierdes tu libro de conjuros, puedes usar el mismo procedimiento para transcribir los conjuros que tienes preparados en un nuevo libro. El resto de tu libro requiere encontrar nuevos conjuros para hacerlo. Muchos magos guardan libros de conjuros de respaldo en un lugar seguro.
>
> ***Apariencia del Libro.*** Tu libro de conjuros es una compilación única de conjuros, con sus propias decoraciones y notas al margen. Podría ser un volumen de cuero funcional y sencillo que recibiste como regalo, un tomo finamente encuadernado con bordes dorados que encontraste en una antigua biblioteca, o incluso una colección suelta de notas reunidas después de perder tu anterior libro de conjuros en un percance.

#### Libro de Conjuros
Tienes un libro de conjuros que contiene seis conjuros de mago de 1er nivel de tu elección. Tu libro de conjuros no contiene tus cantrips conocidos.

#### Preparar y Lanzar Conjuros
La tabla de mago muestra cuántos espacios de conjuro tienes para lanzar tus conjuros de 1er nivel o superior. Para lanzar uno de estos conjuros, debes gastar un espacio del nivel del conjuro o superior. Recuperas los espacios de conjuro gastados cuando terminas un descanso prolongado.

Preparas la lista de conjuros de mago que están disponibles para ti. Para hacerlo, elige un número de conjuros de mago de tu libro de conjuros igual a tu modificador de Inteligencia + tu nivel de mago (mínimo de un conjuro). Los conjuros deben ser de un nivel para el que tengas espacios de conjuro.

Por ejemplo, si eres un mago de 3er nivel, tienes cuatro espacios de conjuro de 1er nivel y dos de 2do nivel. Con una Inteligencia de 16, tu lista de conjuros preparados puede incluir seis conjuros de 1er o 2do nivel, en cualquier combinación, elegidos de tu libro de conjuros. Si preparas el conjuro de 1er nivel *proyectil mágico*, puedes lanzarlo usando un espacio de 1er o 2do nivel. Lanzar el conjuro no lo elimina de tu lista de preparados.

Puedes cambiar tu lista de conjuros preparados cuando terminas un descanso prolongado. Preparar una nueva lista de conjuros de mago requiere tiempo dedicado a estudiar tu libro de conjuros y memorizar los encantamientos y gestos necesarios para lanzar el conjuro: 1 minuto por nivel del conjuro por cada conjuro en tu lista.

#### Habilidad para Lanzar Conjuros
La habilidad para lanzar tus conjuros de mago es la Inteligencia, ya que aprendes tus conjuros mediante el estudio y la memorización dedicados. Usas tu modificador de Inteligencia siempre que un conjuro haga referencia a tu habilidad para lanzar conjuros. Además, usas tu modificador de Inteligencia al establecer la CD de salvación para un conjuro de mago que lanzas y al hacer una tirada de ataque con uno.

<div style="text-align: Center">

**CD de salvación de conjuros** =<br/> 8 + Bonus competencia + Mod. Inteligencia

**Modificador de ataque con conjuros** =<br/> Bonus competencia + Mod. Inteligencia
</div>

#### Lanzamiento de Rituales
Puedes lanzar un conjuro de mago como un ritual si el conjuro tiene la etiqueta de ritual y está en tu libro de conjuros. No necesitas tener el conjuro preparado.

#### Foco para Lanzar Conjuros
Puedes usar un foco arcano como foco para lanzar tus conjuros de mago.

#### Aprender Hechizos
Cada vez que subes de nivel como mago, agregas dos conjuros de mago de tu elección a tu libro de conjuros. Cada uno de estos conjuros debe ser de un nivel para el que tengas espacios de conjuro, como se muestra en la tabla de mago. Durante tus aventuras, podrías encontrar otros conjuros que puedes agregar a tu libro de conjuros (consulta el recuadro "Tu Libro de Conjuros").

<div class='footnote'>CLASES | MAGO</div>

\pagebreakNum

### Sentido Mágico
*Característica de mago de 1er nivel*  
<div style='margin-top:-4px'></div>

Tus estudios te enseñaron a percibir la energía mágica residual. Puedes sentir cuando un conjuro fue lanzado en el último hora en tu ubicación actual y ver escritura creada o usada por magia que esté oculta para otros. Mientras entiendas el idioma, también puedes descifrarla y leerla.

### Escritura Mágica Oculta
Además, puedes crear escritura mágica oculta en cualquier idioma que conozcas.

Otros pueden detectar la presencia del mensaje con una prueba exitosa de Sabiduría (Percepción) con CD 15, pero no podrán descifrarlo sin magia.

### Fuente de Magia
*Característica de mago de 2º nivel*  
<div style='margin-top:-4px'></div>

Accedes a un profundo manantial de magia dentro de ti. Este manantial se representa mediante puntos de hechicería, que te permiten crear una variedad de efectos mágicos.

#### Puntos de Hechicería
Tienes 2 puntos de hechicería y ganas más a medida que alcanzas niveles superiores, como se muestra en la columna de Puntos de Hechicería de la tabla de mago. Nunca puedes tener más puntos de hechicería que los mostrados en la tabla para tu nivel. Recuperas todos los puntos de hechicería gastados cuando terminas un descanso prolongado.

#### Lanzamiento Flexible
Puedes usar tus puntos de hechicería para ganar espacios de conjuro adicionales o sacrificar espacios de conjuro para ganar puntos de hechicería adicionales. Aprendes otras formas de usar tus puntos de hechicería a medida que alcanzas niveles superiores.

***Creación de Espacios de Conjuro***  
Puedes transformar puntos de hechicería no gastados en un espacio de conjuro como una acción adicional en tu turno. Los espacios de conjuro creados desaparecen al final de un descanso prolongado. La tabla de Creación de Espacios de Conjuro muestra el coste de crear un espacio de conjuro de un nivel dado. No puedes crear espacios de conjuro de nivel superior a 5º.

##### Creación de Espacios de Conjuro
| Nivel de Espacio de Conjuro  | Coste en Puntos de Hechicería |
|:-----:|:-----:|
| 1º   |   2   |
| 2º   |   3   |
| 3º   |   5   |
| 4º   |   6   |
| 5º   |   7   |

***Convertir un Espacio de Conjuro en Puntos de Hechicería***  
Como una acción adicional en tu turno, puedes gastar un espacio de conjuro y ganar un número de puntos de hechicería igual al nivel del espacio.

\columnbreak

### Estudio Mágico
*Característica de mago de 2º nivel*  
<div style='margin-top:-4px'></div>

Eliges un estudio mágico que da forma a tu práctica de la magia a través de una de las tres áreas: Arcano, Fuego o Escarcha, detalladas al final de la descripción de la clase.

Tu elección te concede características a nivel 2 y de nuevo a los niveles 6, 10 y 14.

### Metamagia
*Característica de mago de 3º nivel*  
<div style='margin-top:-4px'></div>

A nivel 3, obtienes la capacidad de modificar tus conjuros para que se ajusten a tus necesidades. Ganas dos de las siguientes opciones de Metamagia a tu elección. Obtienes otra opción a nivel 10 y 17. Solo puedes usar una opción de Metamagia en un conjuro cuando lo lanzas, a menos que se indique lo contrario.

#### Conjuro Cuidadoso
Cuando lanzas un conjuro que obliga a otras criaturas a realizar una tirada de salvación, puedes proteger a algunas de esas criaturas del efecto completo del conjuro. Para hacerlo, gastas 1 punto de hechicería y eliges un número de esas criaturas igual a tu modificador de Inteligencia (mínimo una criatura).

Las criaturas elegidas automáticamente tienen éxito en su tirada de salvación contra el conjuro.

#### Conjuro Distante
Cuando lanzas un conjuro con un alcance de 5 pies o más, puedes gastar 1 punto de hechicería para duplicar el alcance del conjuro.

Cuando lanzas un conjuro con un alcance de toque, puedes gastar 1 punto de hechicería para que el alcance del conjuro sea de 30 pies.

#### Conjuro Potenciado
Cuando tiras el daño de un conjuro, puedes gastar 1 punto de hechicería para volver a tirar un número de los dados de daño igual a tu modificador de Inteligencia (mínimo 1). Debes usar los nuevos resultados de los dados.

Puedes usar Conjuro Potenciado incluso si ya has usado otra opción de Metamagia durante el lanzamiento del conjuro.

#### Conjuro Prolongado
Cuando lanzas un conjuro con una duración de 1 minuto o más, puedes gastar 1 punto de hechicería para duplicar su duración, hasta un máximo de 24 horas.

#### Conjuro Potenciado
Cuando lanzas un conjuro que obliga a una criatura a realizar una tirada de salvación para resistir sus efectos, puedes gastar 3 puntos de hechicería para dar a un objetivo del conjuro desventaja en su primera tirada de salvación contra el conjuro.

#### Conjuro Rápido
Cuando lanzas un conjuro con un tiempo de lanzamiento de 1 acción, puedes gastar 2 puntos de hechicería para cambiar el tiempo de lanzamiento a 1 acción adicional para este lanzamiento.

<div class='footnote'>CLASES | MAGO</div>

\pagebreakNum

#### Conjuro Sutil
Cuando lanzas un conjuro, puedes gastar 1 punto de hechicería para lanzarlo sin componentes somáticos ni verbales.

#### Conjuro Gemelo
Cuando lanzas un conjuro que solo tiene un objetivo y no tiene un alcance de uno mismo, puedes gastar un número de puntos de hechicería igual al nivel del conjuro para apuntar a una segunda criatura en el rango con el mismo conjuro (1 punto de hechicería si el conjuro es un truco).

Para ser elegible, un conjuro no debe ser capaz de apuntar a más de una criatura en su nivel actual. Por ejemplo, *misil mágico* y *rayo abrasador* no son elegibles, pero *rayo de escarcha* y *orbe cromático* sí lo son.

> #### Reglas Opcionales del Mago
> Reglas adicionales de Metamagia pueden verse en la página 65 de *Tasha's Cauldron of Everything*.

### Fórmulas de Truco
*Característica de mago de 3.er nivel*  
<div style='margin-top:-4px'></div>

Has inscrito un conjunto de fórmulas arcanas en tu libro de conjuros que puedes usar para formular un truco en tu mente. Siempre que termines un descanso prolongado y consultes esas fórmulas en tu libro de conjuros, puedes reemplazar un truco de mago que conozcas por otro truco de la lista de conjuros de mago.

### Mejora de Característica
*Característica de mago de 4.º nivel*  
<div style='margin-top:-4px'></div>

Cuando alcanzas el 4.º nivel, y de nuevo en los niveles 8, 12, 16 y 19, puedes aumentar una puntuación de característica de tu elección en 2 o puedes aumentar dos puntuaciones de característica de tu elección en 1. Como es normal, no puedes aumentar una puntuación de característica por encima de 20 usando esta característica.

#### Versatilidad Hechicera (Opcional)
Cuando alcanzas un nivel en esta clase que te concede la característica de Mejora de Puntuación de Característica, puedes reemplazar una de las opciones que elegiste para la característica de Metamagia por una opción diferente de Metamagia que esté disponible para ti, representando la forma en que la magia fluye de nuevas maneras dentro de ti.

\columnbreak

### Maestría de Conjuros
*Característica de mago de 18.º nivel*  
<div style='margin-top:-4px'></div>

Has alcanzado tal dominio sobre ciertos conjuros que puedes lanzarlos a voluntad. Elige un conjuro de mago de 1.er nivel y un conjuro de mago de 2.º nivel que estén en tu libro de conjuros.

Puedes lanzar esos conjuros en su nivel más bajo sin gastar un espacio de conjuro cuando los tengas preparados. Si deseas lanzar alguno de estos conjuros en un nivel superior, debes gastar un espacio de conjuro como es habitual.

Puedes pasar 8 horas estudiando para cambiar uno o ambos de los conjuros que escogiste por otros conjuros del mismo nivel.

### Conjuros de Firma
*Característica de mago de 20.º nivel*  
<div style='margin-top:-4px'></div>

Obtienes dominio sobre dos conjuros poderosos y puedes lanzarlos con poco esfuerzo. Elige dos conjuros de mago de 3.er nivel de tu libro de conjuros como tus conjuros de firma. Siempre tienes estos conjuros preparados, no cuentan contra el número de conjuros que puedes preparar, y puedes lanzar cada uno de ellos una vez al nivel 3 sin gastar un espacio de conjuro.

Cuando lo haces, no puedes hacerlo de nuevo hasta que completes un descanso corto o largo. Si deseas lanzar cualquiera de estos conjuros en un nivel superior, debes gastar un espacio de conjuro como es habitual.

## Estudios Mágicos
Los magos son lanzadores de conjuros que favorecen las magias que involucran los elementos cardinales del universo. Los estudiantes dotados de un intelecto agudo y una disciplina inquebrantable pueden recorrer el camino del mago. La magia disponible para los magos es tanto grande como peligrosa, y por lo tanto se revela solo a los practicantes más dedicados.


<img src='https://www.gmbinder.com/images/8W9yFbL.jpg' style='position:absolute; bottom:-250px; right:-173px; width:1000px' />

<img src='https://www.gmbinder.com/images/L60ii4e.png' style='position:absolute; top:105px; left:0px; width:100%; height:100%' />

<img src='https://www.gmbinder.com/images/pbSeYXZ.png' style='position:absolute; top:0px; left:0px; transform:scaleY(-1); width:100%; height:100%' />

<img src='https://www.gmbinder.com/images/e4yq01U.png' style='position:absolute; bottom:160px; right:70px; width:285px' />

<div class='footnote'>CLASES | MAGO</div>

\pagebreakNum

<div style='margin-top:-10px'></div>

### Estudio del Arcano
Los magos arcanos son buscadores de secretos, equilibrando las cambiantes energías místicas. Estos practicantes llevan su conocimiento mágico al límite. Aquellos que dominan este arte son capaces de manipular conjuros a un nivel más primitivo.

#### Truco Adicional
*Rasgo de Estudio del Arcano de nivel 2*  
<div style='margin-top:-4px'></div>

Aprendes el truco *prestidigitación*. Si ya conoces este truco, aprendes un truco de mago diferente de tu elección. El truco no cuenta contra tu número de trucos conocidos.

#### Cargas Arcanas
*Característica de Estudio del Arcano de 2.º nivel*  
<div style='margin-top:-4px'></div>

Siempre que lances un conjuro de mago de nivel 1 o superior, obtienes una carga arcana equivalente al nivel del conjuro, hasta el nivel 5. Los espacios de conjuro de nivel superior a 5 otorgan una carga arcana de nivel 5. Estas cargas duran hasta que se usen, sean reemplazadas por una carga de nivel superior o hasta que haya pasado 1 minuto.

Puedes gastar una carga arcana para otorgarte uno de estos efectos, que dura hasta el final de tu siguiente turno.
- Como una acción adicional, puedes agregar un bono igual al nivel de la carga arcana a las tiradas de ataque y de daño de tu próximo conjuro de mago.
- Como una acción adicional o reacción, puedes agregar un bono igual al nivel de la carga arcana a las tiradas de salvación contra magia o efectos mágicos.

#### Desplazamiento Temporal
*Característica de Estudio del Arcano de 2.º nivel*  
<div style='margin-top:-4px'></div>

Después de tirar iniciativa, pero antes de que la primera criatura tome su turno, puedes intercambiar tu resultado con el resultado de otra criatura que puedas ver. Una vez que lo hagas, no puedes usar esta característica nuevamente hasta que termines un descanso largo.

\columnbreak

#### Brillantez Arcana
*Característica de Estudio del Arcano de 6.º nivel*  
<div style='margin-top:-4px'></div>

Obtienes competencia en Arcano si no la tienes. Tu bonus de competencia se duplica para cualquier prueba de habilidad que realices con ella. Además, siempre estás bajo los efectos del conjuro *entender idiomas*.

#### Presencia Mental
*Característica de Estudio del Arcano de 10.º nivel*  
<div style='margin-top:-4px'></div>

Siempre que creas un espacio de conjuro a partir de puntos de hechicería, también obtienes una carga arcana de nivel equivalente y puedes gastar la carga como parte de la misma acción adicional.

#### Sabio
*Característica de Estudio del Arcano de 10.º nivel*  
___
<div style='margin-top:-6px'></div>

Puedes cambiar tu lista de conjuros preparados de mago cuando terminas un descanso corto o un descanso largo.

#### Distorsión Temporal
*Característica de Estudio del Arcano de 14.º nivel*  
___
<div style='margin-top:-6px'></div>

Puedes ejercer tu control sobre la magia para distorsionar el tiempo. Cuando una criatura que puedas ver dentro de 60 pies de ti comienza su turno, puedes usar tu reacción para permitir que esa criatura tome una acción adicional durante su turno. Cuando lo hagas, obtienes un nivel de agotamiento.

<div class='footnote'>CLASES | MAGO</div>

\pagebreakNum


### Estudio del Fuego
Si bien cualquier mago digno es un experto incomparable en el uso de la magia y está profundamente dedicado a su arte, aquellos que dominan las fuerzas del fuego tienden a ser un poco más audaces que sus compañeros. Estos magos sienten orgullo, e incluso placer, en encender a sus enemigos en estallidos salvajes de llamas.

#### Truco Adicional
*Característica de Estudio del Fuego de 2.º nivel*  
<div style='margin-top:-4px'></div>

Cuando eliges este estudio mágico a nivel 2, aprendes el truco *controlar llamas*. Si ya conoces este truco, aprendes un truco de mago diferente de tu elección. El truco no cuenta contra tu número de trucos conocidos.

#### Racha de Calor
*Característica de Estudio del Fuego de 2.º nivel*  
<div style='margin-top:-4px'></div>

La energía ardiente de tus conjuros se intensifica. Cuando lanzas daño para un conjuro y sacas el número más alto posible en cualquiera de los dados, elige uno de esos dados, lánzalo de nuevo y suma ese resultado al daño. Puedes usar esta característica solo una vez por turno.

A nivel 10, puedes elegir cualquier cantidad de dados que hayan sacado el número más alto posible, pero solo puedes volver a tirar cada dado una vez.

#### Cauterizar
*Característica de Estudio del Fuego de 6.º nivel*  
<div style='margin-top:-4px'></div>

Si te reducen a 0 puntos de golpe, puedes usar tu reacción para recurrir a la energía ardiente que arde en tu interior. En lugar de ser reducido a 0 puntos de golpe, te reduces a 1 punto de golpe, y cada criatura dentro de 10 pies de ti recibe daño de fuego igual a la mitad de tu nivel de mago + tu modificador de Inteligencia.

Una vez que uses esta característica, no podrás usarla de nuevo hasta que termines un descanso largo.

\columnbreak

#### Prender
*Característica de Estudio del Fuego de 10.º nivel*  
<div style='margin-top:-4px'></div>

Cuando infliges daño de fuego con un conjuro usando un espacio de conjuro de hasta 5.º nivel, puedes gastar hasta 3 puntos de hechicería para potenciarlo. Por cada punto de hechicería gastado, añade un dado extra al daño infligido por el conjuro.

Por ejemplo, cuando lanzas *manos ardientes* y gastas 2 puntos, agregas 2d6 adicionales al daño del conjuro. Cuando lanzas un conjuro que hace múltiples tiradas de ataque, como *rayo abrasador*, debes gastar los puntos en cada ataque individualmente.

#### Combustión
*Característica de Estudio del Fuego de 14.º nivel*  
<div style='margin-top:-4px'></div>

Puedes desatar las llamas que arden dentro de ti. Como acción, te envuelves en un torbellino de fuego. Por 1 minuto, obtienes los siguientes beneficios:

- Irradias luz brillante en un radio de 30 pies y luz tenue en 30 pies adicionales.
- Cualquier criatura recibe daño de fuego igual a la mitad de tu nivel de mago si te golpea con un ataque cuerpo a cuerpo.
- Cualquier conjuro o efecto que crees ignora la resistencia al daño de fuego y trata la inmunidad al daño de fuego como resistencia al mismo.
- Eres inmune al daño de fuego y tienes resistencia al daño por frío.
- Tus ataques de conjuro obtienen un golpe crítico con una tirada de 19 o 20 en el d20.

Una vez que uses esta característica, no podrás volver a usarla hasta que termines un descanso largo, a menos que gastes 5 puntos de hechicería para usarla nuevamente.

<div class='footnote'>CLASES | MAGO</div>

\pagebreakNum

### Estudio de la Escarcha
Los magos de escarcha se destacan de sus colegas, ya que su escuela de magia elegida se centra en mantener un control supremo sobre las capacidades de sus enemigos. Los magos que dominan la escarcha realizan exhibiciones heladas en el campo de batalla, inmovilizando a sus enemigos mientras los bombardean con hielo.

#### Truco Adicional
*Característica de Estudio de la Escarcha de 2.º nivel*  
<div style='margin-top:-4px'></div>

Cuando eliges este estudio mágico a nivel 2, aprendes el truco *moldear agua*. Si ya conoces este truco, aprendes un truco de mago diferente de tu elección. El truco no cuenta contra tu número de trucos conocidos.

#### Dedos de Escarcha
*Característica de Estudio de la Escarcha de 2.º nivel*  
<div style='margin-top:-4px'></div>

Obtienes una de las siguientes características a tu elección:

***Barrera de Hielo.*** Puedes tejer el frío a tu alrededor para protegerte. Cuando lanzas un conjuro de 1.er nivel o superior que inflige daño por frío a una criatura, puedes deformar simultáneamente parte de la magia del conjuro para crear una barrera de hielo en ti que dura hasta que termines un descanso largo. La barrera tiene puntos de golpe iguales al doble de tu nivel de mago + tu modificador de Inteligencia. Siempre que recibas daño, la barrera toma el daño en su lugar. Si el daño reduce la barrera a 0 puntos de golpe, recibes cualquier daño restante.

Cuando la barrera se reduce a 0 puntos de golpe, cada criatura a 10 pies de ti ve reducida su velocidad en 10 pies hasta el comienzo de tu próximo turno al estallar la barrera.

Mientras la barrera tenga 0 puntos de golpe, no puede absorber daño, pero su magia permanece. Cada vez que lances un conjuro de 1.er nivel o superior que cause daño por frío, la barrera recupera un número de puntos de golpe igual al doble del nivel del conjuro.

Una vez que crees la barrera, no puedes volver a crearla hasta un descanso largo.

***Elemental de Agua.*** Aprendes a conjurar un elemental de agua. Es amistoso contigo y tus compañeros, y obedece tus órdenes. Consulta las estadísticas del elemental de agua en su bloque de estadísticas.

En combate, el elemental de agua comparte tu cuenta de iniciativa, pero toma su turno inmediatamente después del tuyo. Puede moverse y usar su reacción por sí solo, pero la única acción que toma en su turno es la acción de Esquivar, a menos que uses tu acción adicional para ordenarle que realice una de las acciones en su bloque de estadísticas o las acciones de Correr, Retirarse o Ayudar.

Si apuntas al elemental de agua con un conjuro que inflige daño por frío, se considera inmune al daño y recupera un número de puntos de golpe igual al daño infligido. No necesitas tirar para golpear a tu elemental y automáticamente falla cualquier tirada de salvación si lo eliges.

Al final de un descanso largo, puedes conjurar un nuevo elemental de agua. Si ya tienes un elemental de agua de esta característica, el primero perece de inmediato.

\columnbreak

#### Congelación Cerebral
*Característica de Estudio de la Escarcha de 6.º nivel*  
<div style='margin-top:-4px'></div>

Cada vez que una criatura reciba daño por frío de uno de tus conjuros de mago, su velocidad de movimiento se reduce en 10 pies hasta el final de tu próximo turno.

Cuando una criatura tiene su velocidad reducida de esta manera, puedes gastar un punto de hechicería: esa criatura debe tener éxito en una tirada de salvación de Fuerza contra la CD de salvación de tu conjuro o quedar restringida durante 1 minuto. Si una criatura aterriza un golpe exitoso contra la criatura, las condiciones causadas por Congelación Cerebral se eliminan.

A partir del nivel 14, la criatura se vuelve paralizada en lugar de restringida.

#### Manos de Escarcha
*Característica de Estudio de la Escarcha de 10.º nivel*  
<div style='margin-top:-4px'></div>

Obtienes una de las siguientes características, dependiendo de tu elección a nivel 2.

***Barrera de Hielo.*** Cuando una criatura que puedes ver dentro de 30 pies de ti recibe daño, puedes usar tu reacción para hacer que tu Barrera de Hielo se manifieste alrededor de ella y absorba el daño. Si este daño reduce la barrera a 0 puntos de golpe, la criatura barricada recibe cualquier daño restante.

Además, ahora puedes gastar puntos de hechicería para causar el efecto de Congelación Cerebral.

***Elemental de Agua.*** Tu elemental de agua se convierte en un elemental de hielo y obtiene los siguientes beneficios adicionales:

- Gana inmunidad al daño por frío.
- Congelación Cerebral ahora se aplica al daño por frío causado por el elemental.
- Puede lanzar el conjuro *tormenta de hielo* una vez por descanso largo, usando tu CD de salvación de conjuros (requiere tu acción adicional).

#### Anillo de Escarcha
*Característica de Estudio de la Escarcha de 14.º nivel*  
<div style='margin-top:-4px'></div>

Puedes usar tu acción para conjurar un anillo de runas mágicas que invoca el frío más profundo alrededor de un punto que elijas dentro de 60 pies. El anillo tiene un radio de 30 pies y llena un cilindro de 10 pies de altura con frío gélido.

Las criaturas dentro del área deben tener éxito en una tirada de salvación de Fuerza contra la CD de salvación de tus conjuros o quedar paralizadas hasta 1 minuto o hasta que reciban daño. Si el cuerpo de una criatura está completamente dentro del área, la tirada de salvación se realiza con desventaja. En una tirada de salvación exitosa, la criatura no queda restringida.

Además, las criaturas que pasan por el área por medios no mágicos tienen su velocidad de movimiento reducida a la mitad hasta el final de su próximo turno después de salir del área. Además, los ataques a distancia realizados a través del área se hacen con desventaja.

Una vez que uses esta característica, no podrás volver a usarla hasta que termines un descanso largo.

<div class='footnote'>PARTE 1 | CLASES</div>

\pagebreakNum

___
> ## Elemental de Agua
>*Elemental mediano, neutral*  
> ___
> - **CA** 13 + PB (armadura natural)
> - **PG** 2 + Mod. Inteligencia + 5 x nivel de mago (tiene un número de Dados de Golpe [d8] igual a tu nivel de mago)
> - **Velocidad** 30 pies, nadar 40 pies
>___
>|FUE|DES|CON|INT|SAB|CAR|
>|:---:|:---:|:---:|:---:|:---:|:---:|
>|14 (+2)|12 (+1)|14 (+2)|4 (-3)|10 (+0)|6 (-2)|
>___
> - **Habilidades** Percepción +2 + PB
> - **Inmunidades al Daño** Veneno
> - **Inmunidades a Condiciones** Agotamiento, Petrificado, Envenenado
> - **Sentidos** Visión en la oscuridad 60 pies, Percepción pasiva 12
> - **Idiomas** entiende los idiomas de su creador, pero no puede hablar
> - **Bonus de Competencia** (PB) igual a tu bonus de competencia
> ___
>
> #### Acciones (Requiere Acción Adicional)  
> ###  
>
> ***Golpe.*** *Ataque Cuerpo a Cuerpo:* tu modificador de ataque de conjuros para golpear, alcance 5 pies, un objetivo. <br/> 
*Impacto:* 1d8 + 2 + PB de daño contundente.
>
> ***Rayo de Escarcha.*** *Ataque de Conjuro a Distancia:* tu modificador de ataque de conjuros para golpear, alcance 30/60 pies, un objetivo. <br/>
*Impacto:* 1d6 + 2 + PB de daño por frío.
>
> ***Restaurar (3/día).*** Las magias dentro del elemental de agua restauran 2d8 + PB puntos de golpe a sí mismo.
>
> ### Reacciones
> ***Congelar.*** Cuando una criatura a tu alcance golpea al elemental de agua con un ataque cuerpo a cuerpo, el elemental puede intentar agarrarla.

<img src='https://www.gmbinder.com/images/jIlkFOD.png' style='position:absolute; top:0px; right:0px; width:400px' />
<img src='https://www.gmbinder.com/images/huxbNse.png' style='position:absolute; top:-130px; right:-25px; height:100%' />

<div class='footnote'>PARTE 1 | CLASES</div>

\pagebreakNum

## Monje
*Preguntar por qué luchamos... es preguntar por qué caen las hojas. Está en su naturaleza. Tal vez, haya una mejor pregunta. ¿Por qué luchamos? Para proteger el hogar y la familia... Para preservar el equilibrio y traer armonía.*  
<div style="text-align:Right">

*— Chen Cerveza de Trueno* &nbsp;</div>

Un orco, vestido con ropas sueltas, toma una profunda respiración y ajusta su postura. Cuando los primeros atacantes lo alcanzan, exhala un cono de fuego, envolviendo a sus enemigos.

Un gnomo, situado detrás de sus aliados mientras los ataques llueven sobre ellos, concentra su chi, manifestando una estatua de jade puro, mientras envía un rayo de chi que alivia las heridas de un aliado.

Un tauren salta sobre una barricada, lanzándose al grupo de gnolls del otro lado. Gira entre ellos, desviando sus ataques y haciéndolos retroceder, hasta quedar sola.

Sea cual sea su disciplina, los monjes comparten la habilidad de canalizar mágicamente la energía que fluye por sus cuerpos. Ya sea a través de una destreza en combate impresionante o un enfoque en defensa y velocidad, esta energía impregna todo lo que un monje hace.

### El Flujo del Chi
Los monjes estudian la energía mágica conocida como chi, la palabra pandaren para 'espíritu'. Utilizan la energía interna que fluye a través de cada ser viviente, canalizándola para crear efectos mágicos y superar los límites físicos de sus cuerpos. Gracias a esta energía, los monjes infunden una velocidad y fuerza asombrosas en sus golpes desarmados. A medida que ganan experiencia, su dominio del chi les otorga mayor control sobre sus propios cuerpos y los de sus enemigos.

### Entrenamiento y Ascetismo
PPequeños monasterios amurallados están esparcidos por el mundo, refugios apartados del ritmo de la vida cotidiana, donde el tiempo parece detenerse. Los monjes que viven allí buscan la perfección personal mediante la contemplación y el entrenamiento riguroso. Muchos llegaron al monasterio siendo niños, ya sea porque sus padres murieron, no había comida para sostenerlos, o en agradecimiento por algún favor recibido de los monjes.

Algunos monjes viven totalmente apartados, aislados de todo lo que pudiera interferir con su progreso espiritual. Otros hacen un juramento de aislamiento, saliendo solo para actuar como espías o asesinos al servicio de su líder, patrón u otra potencia.

La mayoría de los monjes, sin embargo, no evitan a sus vecinos y visitan a menudo las aldeas cercanas, intercambiando servicios por alimentos y bienes. Como guerreros versátiles, muchos terminan protegiendo a sus comunidades de monstruos o tiranos.

### Creando un Monje
Al crear a tu personaje monje, considera la conexión con el monasterio donde aprendiste tus habilidades y pasaste tus años formativos. ¿Eras un huérfano o fuiste dejado en la puerta del monasterio? ¿Tus padres te prometieron al monasterio en agradecimiento por un favor? ¿Ingresaste para ocultarte de un crimen? ¿O elegiste la vida monástica por voluntad propia?

<div class='footnote'>PARTE 1 | CLASES</div>
<img src='https://www.gmbinder.com/images/NYSqgLC.jpg' style='position:absolute; top:0px; right:-400px; width:1500px' />
<img src='https://www.gmbinder.com/images/76ytPWI.png' style='position:absolute; top:100px; right:0px; width:800px' />
<img src='https://www.gmbinder.com/images/E8GrMME.png' style='position:absolute; top:0px; right:0px; width:900px' />
<img src='https://www.gmbinder.com/images/cUVZ02S.png' style='position:absolute; top:200px; right:-60px; width:500px' />

\pagebreakNum

<div style='margin-top:70px;'></div>

<div class='classTable wide'>

##### El Monje
| Nivel | Bonificación<br>de Competencia | &nbsp; | Artes<br>Marciales | &nbsp; | Puntos<br>de Chi | &nbsp; | Características |
|:---:|:-:|-|:-:|-|:-:|-|:-------------------------------------------------|
| 1° | +2 || 1d4 || — || Defensa sin Armadura, Artes Marciales              |
| 2° | +2 || 1d4 || 2 || Chi, Rodar                                        |
| 3° | +2 || 1d4 || 3 || Tradición Monástica, Serenidad                    |
| 4° | +2 || 1d4 || 4 || Mejora de Puntuación de Característica            |
| 5° | +3 || 1d6 || 5 || Ataque Adicional, Palma Aturdidora                |
| 6° | +3 || 1d6 || 6 || Característica de la Tradición Monástica, Golpes Empoderados por el Chi |
| 7° | +3 || 1d6 || 7 || Evasión, Desintoxicación                          |
| 8° | +3 || 1d6 || 8 || Mejora de Puntuación de Característica            |
| 9° | +4 || 1d6 || 9 || Trascendencia                                     |
| 10°| +4 || 1d6 || 10 || Paz Interior                                     |
| 11°| +4 || 1d8 || 11 || Característica de la Tradición Monástica         |
| 12°| +4 || 1d8 || 12 || Mejora de Puntuación de Característica           |
| 13°| +5 || 1d8 || 13 || Viento de Jade Acelerado                         |
| 14°| +5 || 1d8 || 14 || Difusión de la Magia                             |
| 15°| +5 || 1d8 || 15 || Cuerpo Atemporal                                 |
| 16°| +5 || 1d8 || 16 || Mejora de Puntuación de Característica           |
| 17°| +6 ||1d10|| 17 || Característica de la Tradición Monástica          |
| 18°| +6 ||1d10|| 18 || Bendición de Agosto, Mejora de Trascendencia      |
| 19°| +6 ||1d10|| 19 || Mejora de Puntuación de Característica            |
| 20°| +6 ||1d10|| 20 || Zen Perfecto                                      |
</div>

&nbsp;&nbsp;&nbsp; Considera por qué dejaste el monasterio. ¿Fuiste elegido por tu líder para una misión importante? ¿Fuiste expulsado por violar las reglas? ¿Temías partir o estabas feliz de irte? ¿Tienes algún objetivo fuera del monasterio o anhelas regresar a tu hogar? Debido a la vida estructurada del monasterio y la disciplina requerida para dominar el chi, los monjes suelen tener un alineamiento legal.

#### Creación Rápida
Haz que tu puntuación más alta sea Destreza, seguida por Sabiduría.

#### Multiclase

***Característica Mínima.*** Debes tener al menos 13 en Destreza y Sabiduría para coger un nivel en esta clase, o para coger un nivel en otra clase si ya eres un monje.

***Competencias Adquiridas.*** Armadura ligera, armas simples, espadas cortas.

\columnbreak

<div style='margin-top:-10px;'></div>

## Rasgos de Clase

#### Puntos de Golpe
___
- **Dados de Golpe:** 1d8 por nivel de monje
- **PG al 1:** 8 + Mod. Constitución
- **PG por nivel:** 1d8 (o 5) + Mod. Constitución por cada nivel de monje

#### Competencias
___
- **Armadura:** Armadura ligera
- **Armas:** Armas simples, espadas cortas
- **Herramientas:** Elige un tipo de herramientas de artesano o un instrumento musical
- **Tiradas de Salvación:** Fuerza, Destreza
- **Habilidades:** Elige dos entre Acrobacias, Atletismo, Historia, Perspicacia, Religión y Sigilo

#### Equipo
 - *(a)* una espada corta o *(b)* cualquier arma simple
 - *(a)* una mochila de aventurero o *(b)* una mochila de explorador
 - 10 dardos

<div class='footnote'>PARTE 1 | CLASES</div>
<img src='https://www.gmbinder.com/images/eec1Qjq.png' style='position:absolute; top:-70px; right:50px; width:700px' />

\pagebreakNum

### Defensa sin Armadura
A partir del 1er nivel, mientras no lleves armadura ni estés empuñando un escudo, tu CA será igual a 10 + tu modificador de Destreza + tu modificador de Sabiduría.

### Artes Marciales
En el 1er nivel, tu práctica de las artes marciales te da maestría en estilos de combate que usan golpes desarmados y armas de monje, que son las espadas cortas y cualquier arma cuerpo a cuerpo simple que no tenga la propiedad de dos manos ni pesada.

Obtienes los siguientes beneficios mientras estás desarmado o empuñando solo armas de monje y no llevas armadura de malla o de placas, ni empuñas un escudo:

 - Puedes usar Destreza en lugar de Fuerza para las tiradas de ataque y daño de tus golpes desarmados y armas de monje.
 - Puedes tirar un d4 en lugar del daño normal de tu golpe desarmado o arma de monje. Este dado cambia a medida que ganas niveles como monje, como se muestra en la columna de Artes Marciales de la tabla de Monje.
 - Cuando usas la acción de Ataque con un golpe desarmado o un arma de monje en tu turno, puedes realizar un golpe desarmado como acción adicional. Por ejemplo, si tomas la acción de Ataque y atacas con un bastón, puedes realizar también un golpe desarmado como acción adicional.

### Chi
A partir del 2º nivel, tu entrenamiento te permite aprovechar la energía mística del chi. Tu acceso a esta energía se representa por una cantidad de puntos de chi. Tu nivel de monje determina cuántos puntos tienes, como se muestra en la columna de Puntos de Chi de la tabla de Monje.

Puedes gastar estos puntos para alimentar varias características de chi. Comienzas conociendo cuatro de estas características: Puños de Furia, Danza Elusiva, Paso del Viento y Efusión. Aprendes más características de chi a medida que subes de nivel en esta clase.

Cuando gastas un punto de chi, no está disponible hasta que termines un descanso corto o largo, al final del cual recuperas todos los puntos de chi gastados. Debes pasar 30 minutos del descanso meditando para recuperar tus puntos de chi.

Algunas de tus características de chi requieren que tu objetivo haga una tirada de salvación para resistir sus efectos. La CD de la tirada de salvación se calcula de la siguiente manera:

<div style="text-align: Center">

**CD de salvación de Chi** = <br>8 + Bonus competencia + Mod. Sabiduría
</div>

#### Puños de Furia
Inmediatamente después de tomar la acción de Ataque en tu turno, puedes gastar 1 punto de chi para realizar dos golpes desarmados como acción adicional.

#### Danza Elusiva
Puedes gastar 1 punto de chi para tomar la acción de Esquivar como acción adicional en tu turno.

\columnbreak

#### Paso del Viento
Puedes gastar 1 punto de chi para tomar la acción de Desenganche o Carrera como acción adicional en tu turno, y tu distancia de salto se duplica por ese turno.

#### Efusión
Puedes gastar 1 punto de chi y usar tu acción adicional para tocar a una criatura. La criatura recupera puntos de golpe iguales a tu modificador de Sabiduría.

### Rodar
A partir del 2º nivel, puedes rodar por el campo de batalla cuando no estés empuñando un escudo. Una vez por turno, puedes gastar movimiento para rodar una cantidad de pies en línea recta igual al movimiento gastado. Puedes rodar a través del espacio de criaturas hostiles, sin embargo, no puedes terminar tu rodar dentro de su espacio.

Cualquier ataque de oportunidad realizado contra ti mientras estás rodando se hace con desventaja.

### Tradición Monástica
Cuando alcanzas el 3er nivel, te comprometes con una tradición monástica: el Camino del Maestro Cervecero, el Camino del Tejedor de Niebla o el Camino del Caminante del Viento, todos detallados al final de la descripción de la clase. Tu tradición te otorga características en el 3er nivel y de nuevo en el 6º, 11º y 17º nivel.

### Serenidad
En el 3er nivel, puedes entrar en una postura serena durante 1 minuto cuando usas puntos de chi. Mientras estés en esta postura, usas tu modificador de Sabiduría para tus tiradas de ataque y daño cuando ataques con un arma de monje o tus golpes desarmados.

Tu serenidad termina de manera prematura si te vuelves encantado, asustado o incapacitado, o si intentas realizar una tarea más extenuante que interactuar con un objeto.

### Mejora de Característica
Cuando llegas al 4º nivel, y de nuevo en los niveles 8º, 12º, 16º y 19º, puedes aumentar una puntuación de característica de tu elección en 2, o puedes aumentar dos puntuaciones de características de tu elección en 1. Como de costumbre, no puedes aumentar una puntuación de característica por encima de 20 usando esta característica.

### Ataque Adicional
A partir del 5º nivel, puedes atacar dos veces, en lugar de una, siempre que tomes la acción de Ataque en tu turno.

### Palma Aturdidora
A partir del 5º nivel, puedes interferir con el flujo de chi en el cuerpo de un oponente. Una vez por turno, cuando golpees a otra criatura con un ataque cuerpo a cuerpo, puedes gastar 1 punto de chi para intentar un golpe aturdidor. El objetivo debe tener éxito en una tirada de salvación de Constitución o quedar aturdido hasta el final de tu próximo turno.

<div class='footnote'>PARTE 1 | CLASES</div>

\pagebreakNum

### Golpes Empoderados por el Chi
A partir del 6º nivel, tus golpes desarmados cuentan como mágicos para propósitos de superar resistencias e inmunidades a ataques y daño no mágicos.

### Evasión
En el 7º nivel, tu agilidad instintiva te permite esquivar ciertos efectos de área, como el aliento de escarcha de un dragón azul o el hechizo *bola de fuego*. Cuando te someten a un efecto que te permite realizar una tirada de salvación de Destreza para recibir solo la mitad del daño, en su lugar no recibes daño si tienes éxito en la tirada de salvación, y recibes la mitad de daño si fallas.

### Desintoxicación
A partir del 7º nivel, puedes usar tu acción para eliminar una enfermedad o condición de envenenado que te esté afectando.


### Trascendencia
Al alcanzar el 9º nivel, puedes concentrar tu chi en una imagen incorpórea de ti mismo a la que podrás trasladarte en el futuro. Puedes usar tu acción y gastar 1 punto de chi para invocar la imagen en tu espacio; la imagen es incorpórea y no se puede interactuar con ella. La imagen permanece durante 1 minuto antes de desaparecer.

Mientras estés a 60 pies de ella, puedes usar tu acción adicional para trascender el mundo material y teletransportarte al espacio de la imagen. La imagen incorpórea desaparece entonces.

En el 18º nivel, tu imagen de jade incorpórea permanece durante 1 hora, y el rango al que puedes trascender a ella se incrementa a 1 milla.

### Paz Interior
A partir del 10º nivel, puedes usar tu acción adicional y gastar 1 punto de chi para finalizar un efecto que te esté causando estar hechizado o asustado.

\columnbreak

### Viento de Jade Impetuoso
A partir del 13º nivel, inmediatamente después de que tomes la acción de Ataque en tu turno, puedes gastar 1 punto de chi y elegir cualquier número de criaturas a 5 pies de ti. Un objetivo debe tener éxito en una tirada de salvación de Destreza o ser empujado 10 pies directamente lejos de ti. Un objetivo empujado de esta manera provoca ataques de oportunidad de criaturas cercanas.

### Dispersar Magia
En el 14º nivel, tu flujo de chi te fortalece contra conjuros y efectos dañinos. Tienes ventaja en todas las tiradas de salvación de Inteligencia, Sabiduría y Carisma contra magia.

### Cuerpo Atemporal
A partir del 15º nivel, tu chi te sostiene de manera que no sufres los efectos de la vejez, y no puedes ser envejecido mágicamente. Aun puedes morir de vejez, sin embargo. Además, ya no necesitas comida ni agua.

### Bendición Augusta
A partir del 18º nivel, cada vez que hagas una tirada de salvación y falles, puedes gastar 1 punto de chi para volver a tirarla. Debes usar el nuevo resultado.

### Zen Perfecto
En el 20º nivel, cuando tires para iniciativa y no tengas puntos de chi restantes, recuperas 4 puntos de chi.

<div class='footnote'>PARTE 1 | CLASES</div>
<img src='https://www.gmbinder.com/images/ZUiw9ln.jpg' style='position:absolute; top:760px; right:0px; width:800px' />
<img src='https://www.gmbinder.com/images/3e9S91s.png' style='position:absolute; top:-250px; right:0px; width:900px' />

\pagebreak

## Tradiciones Monásticas
Hay muchas tradiciones monásticas que han dejado su huella en Azeroth, algunas similares a los artistas marciales de Pandaria y otras mucho más únicas. Tres de estas tradiciones son honradas entre los monjes y enseñadas. Las tres tradiciones dependen de las mismas técnicas básicas, divergentes a medida que el estudiante se vuelve más hábil. Por tanto, un monje solo necesita elegir una tradición al alcanzar el 3er nivel.

### Camino del Maestro Cervecero
Los Maestros Cerveceros suelen ser excéntricos y alegres; muchos los considerarían simplemente como bufones que disfrutan de una bebida para traer alegría a los afligidos o para demostrar humildad a los arrogantes, pero cuando la batalla se une, el maestro cervecero puede ser un enemigo enloquecedor y magistral.

#### Competencia Adicional
A partir del 3er nivel, obtienes competencia con herramientas de cervecero. Si ya eres competente con estas herramientas, tu bonificación de competencia se duplica para cualquier prueba de habilidad que hagas con ellas.

#### Cervecero Elusivo
En el 3er nivel, aprendes a canalizar tu chi en brebajes que potencian tus poderes.

Conoces el brebaje del Buey Negro y otro brebaje de tu elección, todos los cuales se detallan en la sección "Brebajes Elusivos" a continuación. Aprendes un brebaje adicional de tu elección en los niveles 6º, 11º y 17º.

Cuando ganas un nivel en esta clase, puedes elegir uno de los brebajes que conoces y reemplazarlo por otro brebaje que podrías aprender en ese nivel.

***Uso de los Brebajes Elusivos.*** Todos tus brebajes elusivos requieren una acción para ser utilizados. Cuando tomas la acción, eliges el brebaje conocido que deseas beber y gastas puntos de chi igual a su costo. Un brebaje requiere que gastes puntos de chi cada vez que lo uses, a menos que se especifique lo contrario.

Para usar cualquiera de tus brebajes conocidos, debes tener un frasco de líquido potable contigo, ya que todos los brebajes requieren que canalices chi en algún líquido mientras lo bebes.

#### Tambaleo
A partir del 6º nivel, aprendes a resistir ataques dañinos contra ti. Puedes usar tu reacción al recibir daño para darte resistencia a todo el daño infligido por el ataque, excepto daño psíquico.

Puedes usar esta característica dos veces. Recuperas los usos gastados cuando terminas un descanso corto o largo.

\columnbreak

#### Elaboración Ligera
A partir del 11º nivel, cuando usas tu acción para beber un brebaje, puedes realizar un golpe desarmado como acción adicional.

En el 17º nivel, esto aumenta a dos golpes desarmados.

#### Brebajes Elusivos
Los brebajes elusivos se presentan en orden alfabético. Si un brebaje requiere un nivel, debes tener ese nivel en esta clase para aprender el brebaje.

***Brebaje del Buey Negro.*** Puedes gastar 1 punto de chi para darte ventaja en el próximo ataque cuerpo a cuerpo que realices dentro de 1 minuto. Puedes realizar un ataque cuerpo a cuerpo como parte de la misma acción.

***Brebaje del Desmayo (Requiere 11º nivel).*** Puedes gastar 3 puntos de chi para obtener los efectos del hechizo *desenfoque* durante 1 minuto.

***Aliento de Fuego (Requiere 6º nivel).*** Puedes gastar 2 puntos de chi para exhalar fuego en un cono de 15 pies. Cada criatura en el área debe realizar una tirada de salvación de Destreza, recibiendo daño por fuego igual a tu nivel de Monje + tu modificador de Sabiduría si falla la tirada, o la mitad de daño si tiene éxito.

#### Brebaje Fortificante
Puedes gastar 1 punto de chi para ganar puntos de golpe temporales iguales a la mitad de tu nivel de Monje + tu modificador de Sabiduría.

#### Brebaje Vigorizante (Requiere Nivel 11)
Puedes gastar 4 puntos de chi para obtener los efectos del conjuro *prisa* durante 1 minuto.

#### Brebaje de Piel de Hierro (Requiere Nivel 6)
Puedes gastar 2 puntos de chi para ganar resistencia al daño contundente, perforante y cortante infligido por ataques no mágicos durante 1 minuto.

#### Brebaje Agil (Requiere Nivel 11)
Puedes gastar 3 puntos de chi para obtener los efectos del conjuro *libertad de movimiento* durante 1 minuto.

#### Brebaje Purificador (Requiere Nivel 17)
Puedes gastar 5 puntos de chi para lanzar *restauración mayor* sobre ti mismo.

#### Té de Trueno
Puedes gastar 1 punto de chi para ganar la fuerza de Xuen. Hasta el final de tu próximo turno, tus ataques cuerpo a cuerpo infligen daño adicional por trueno igual a tu modificador de Sabiduría.

\pagebreakNum

### Camino del Tejedor de Niebla
Los Tejedores de Niebla son únicos entre los que sanan. Canalizan energías que son misteriosas, a menudo malinterpretadas por los aldeanos como algún tipo de medicina popular. Pero aquellos que tejen las nieblas manejan el poder de la esencia de la vida, usando una mezcla de conjuros preventivos y restaurativos para sanar las heridas de sus aliados.

#### Niebla Calmante
A partir del 3er nivel, tienes un reservorio de chi sanador que se repone cuando tomas un descanso prolongado. Con ese reservorio, puedes restaurar un número total de puntos de golpe igual a tu nivel de monje x 10.

Como acción, puedes manifestar un rayo de chi hacia una criatura a 30 pies de ti y extraer poder del reservorio para restaurar un número de puntos de golpe a esa criatura, hasta el máximo que quede en tu reservorio.

Alternativamente, puedes gastar 5 puntos de tu reservorio de sanación para curar una enfermedad o neutralizar un veneno que afecte al objetivo. Puedes curar múltiples enfermedades y neutralizar múltiples venenos con un solo uso de Niebla Calmante, gastando puntos de golpe por separado para cada uno.

Esta característica no tiene efecto en muertos vivientes ni constructos.

#### Palma de Chi-Ji
A nivel 3, cuando usas tu característica de Niebla Calmante, puedes realizar un golpe desarmado como acción adicional y puedes usar tu modificador de Sabiduría para la tirada de ataque y de daño con este ataque.

#### Caminante de la Niebla
A partir del 6º nivel, puedes teletransportarte distancias cortas a través de la niebla. Como acción, puedes gastar 1 punto de chi y teletransportarte 60 pies a un espacio desocupado que puedas ver. Como parte de la misma acción, puedes usar tu Niebla Calmante en un objetivo dentro del alcance de tu nueva posición.

#### Anillo de Paz
Al alcanzar el nivel 11, puedes usar tu acción y elegir un número de criaturas dentro de 15 pies de ti igual a tu modificador de Sabiduría. Un objetivo debe tener éxito en una tirada de salvación de Sabiduría o quedar incapacitado hasta el final de tu próximo turno o hasta que reciba daño.

Puedes usar esta característica un número de veces igual a tu modificador de Sabiduría. Recuperas los usos gastados cuando terminas un descanso prolongado.

#### Estatua del Dragón de Jade
A nivel 17, puedes dar forma física a tu chi, moldeándolo en una estatua de Yu'lon, el Dragón de Jade. Puedes gastar 3 puntos de chi como acción y elegir un espacio vacío a 30 pies de ti para manifestar una estatua de jade. La estatua tiene puntos de golpe igual al doble de tu nivel de monje, resistencia a todo el daño e inmunidad al daño psíquico y por veneno. Siempre que uses tu característica de Niebla Calmante, puedes elegir un segundo objetivo dentro de 60 pies de la estatua para ser sanado por la mitad de los puntos de golpe que restores.

La estatua permanece durante 1 minuto o hasta que sea destruida.

\columnbreak

### Camino del Caminavientos
Entre los monjes, ninguno ha dominado las artes marciales como los caminavientos, y pocos en Azeroth pueden luchar con su gracia. Los caminavientos poseen una destreza física inigualable y son capaces de abrumar a sus enemigos con una deslumbrante ráfaga de puñetazos y patadas.

#### Golpes de Mano de Lanza
Al elegir esta tradición a nivel 3, puedes manipular el chi de tu enemigo cuando canalizas el tuyo propio. Siempre que golpees a una criatura con uno de los ataques otorgados por tus Puños de Furia, puedes imponer uno de los siguientes efectos en ese objetivo:

- Debe tener éxito en una tirada de salvación de Destreza o ser derribado.
- Debe hacer una tirada de salvación de Fuerza. Si falla, puedes empujarlo hasta 15 pies lejos de ti.
- No puede tomar reacciones hasta el final de tu próximo turno.

#### Reflejos del Tigre
También a nivel 3, reaccionas con la rapidez de un tigre. Puedes darte un bono a tu iniciativa igual a tu modificador de Sabiduría.

#### Caminavientos
A partir del 6º nivel, cuando usas la característica de chi Paso del Viento, obtienes una velocidad de vuelo igual a la mitad de tu velocidad de movimiento hasta el final de tu turno. Si terminas tu turno en el aire, caes al suelo inmediatamente.

Además, puedes usar tu reacción cuando caes para reducir cualquier daño por caída que recibas en una cantidad igual al doble de tu nivel de monje.

#### Golpes Impredecibles
Al alcanzar el nivel 11, siempre que realices un ataque de oportunidad, puedes gastar 1 punto de chi para usar tu característica Puños de Furia contra el objetivo en su lugar.

#### Palma Temblorosa
A nivel 17, puedes generar vibraciones letales en el cuerpo de una persona. Cuando golpeas a una criatura con un golpe desarmado, puedes gastar 3 puntos de chi para iniciar estas vibraciones imperceptibles, que duran un número de días igual a tu nivel de monje. Las vibraciones son inofensivas a menos que uses tu acción para terminarlas. Para hacerlo, tú y el objetivo deben estar en el mismo plano de existencia. Cuando lo hagas, la criatura debe realizar una tirada de salvación de Constitución. Si falla, sus puntos de golpe se reducen a 0. Si tiene éxito, recibe 10d10 de daño necrótico.

Solo puedes tener una criatura bajo el efecto de esta característica a la vez. Puedes elegir terminar las vibraciones sin causar daño usando una acción.

<div class='footnote'>PARTE 1 | CLASES</div>

\pagebreakNum

<div style='margin-top:322px;'></div>

## Paladín
*La Luz, sí. Pero deberíamos dejar que nos guíe, no que<br> nos comande. También tenemos nuestras propias mentes <br> y corazones. Debemos hacer uso de ellos también.*

<br> <span style="margin-left:130px"></span> *— Alto Exarca Turalyon*  
<div style='margin-top:0px;'></div>  

Cubierta con una armadura de placas que brilla bajo el sol, a pesar del polvo y la suciedad del viaje, una humana deja su espada y escudo y coloca sus manos sobre un hombre herido. Un resplandor divino emana de sus manos, cerrando sus heridas y abriendo sus ojos con asombro.

Un enano se agacha tras una roca, su capa negra casi lo hace invisible en la noche. Observa a una banda de guerra orca celebrando su victoria, y se desliza entre ellos en silencio, murmura una plegaria, y dos orcos caen muertos sin advertir su presencia.

Con su cabello plateado brillando bajo un rayo de luz, un elfo de sangre ríe con exaltación. Su lanza brilla con resplandor divino mientras ataca repetidamente a un demonio gigante, hasta que su luz vence la forma vil.

Sin importar su origen o misión, los paladines están unidos por la Luz para enfrentarse al mal. La Luz convierte a un guerrero devoto en un campeón bendecido.

### Juramento del Paladín
Este es el juramento del paladín: proteger a los débiles, llevar justicia a los injustos y erradicar el mal de los rincones más oscuros del mundo. Estos guerreros sagrados están equipados con armaduras de placas para enfrentar a los enemigos más duros, y la bendición de la Luz les permite sanar heridas e, incluso, en algunos casos, devolver la vida a los muertos. Listos para servir, los paladines pueden defender a sus aliados con espada y escudo o blandir poderosas armas a dos manos contra sus enemigos. La Luz les otorga poder adicional contra los no-muertos y demonios, asegurando que estas criaturas profanas no corrompan más el mundo.

Los paladines no solo son fanáticos, sino guardianes de los justos, y otorgan bendiciones a aquellos sobre los que la Luz desea brillar. La Luz emana de los paladines, y los aliados dignos que están cerca de ellos se ven fortalecidos por su poder.

\columnbreak

<div style='margin-top:555px;'></div>

### Más Allá de una Vida Mundana
La vida de un paladín es, por definición, una vida de aventuras. Cada paladín vive en la primera línea de la lucha cósmica contra el mal, a menos que una lesión lo aparte temporalmente. Los paladines son raros incluso entre los guerreros, y aquellos que reciben el llamado dejan atrás sus vidas anteriores para tomar las armas contra el mal. A veces, sirven a la corona como líderes de grupos élite de caballeros, pero su lealtad siempre es primero a la causa de la rectitud, no a la corona ni al país.

Los paladines aventureros toman su misión muy en serio. Incursionar en ruinas antiguas o criptas polvorientas puede ser una misión con un propósito superior, más allá del simple deseo de tesoros. El mal acecha en todas partes, y cada pequeña victoria contra él puede inclinar el equilibrio cósmico lejos del olvido.

### Creando un Paladín
El aspecto más importante de un personaje paladín es la naturaleza de su misión sagrada. Aunque las características de clase relacionadas con tu camino no aparecen hasta que alcanzas el nivel 3, planea con anticipación esa elección leyendo las descripciones del camino al final de la clase. ¿Eres un devoto servidor del bien, leal a la luz, la justicia y el honor, un caballero sagrado que sale a combatir el mal? ¿O eres un glorioso campeón de la luz, que aprecia todo lo bello que se enfrenta a las sombras?

<div class='footnote'>PARTE 1 | CLASES</div>
<img src='https://www.gmbinder.com/images/xI58PYW.png' style='position:absolute; top:-230px; right:-330px; width:1500px' />
<img src='https://www.gmbinder.com/images/vn90cy3.png' style='position:absolute; top:-120px; right:0px; width:970px' />
<img src='https://www.gmbinder.com/images/fgaRuZW.png' style='position:absolute; top:-40px; right:-50px; width:560px;transform:scalex(-1)' />

\pagebreakNum

<div class='classTable wide'>

##### El Paladín
|Nivel|Bonus de<br>Competencia|Características|1°|&nbsp;|2°|&nbsp;|3°|&nbsp;|4°|&nbsp;|5° <div style="position: absolute; top:100px; right:62px; width:200px; height:25px">— Ranuras de Hechizo por Nivel —</div>|
|:---:|:--:|:----------------------------------|:--:|:-|:--:|:-|:--:|:-|:--:|:-|:--:|
| 1  | +2 | Sentido Divino, Imposición de Manos                    |—||—||—||—||—|
| 2  | +2 | Estilo de Combate, Lanzamiento de Hechizos, Golpe del Cruzado |2||—||—||—||—|
| 3  | +2 | Camino Sagrado                                          |3||—||—||—||—|
| 4  | +2 | Mejora de Característica                  |3||—||—||—||—|
| 5  | +3 | Ataque Extra                                            |4||2||—||—||—|
| 6  | +3 | Aura de Protección                                      |4||2||—||—||—|
| 7  | +3 | Rasgo de Camino Sagrado                                 |4||3||—||—||—|
| 8  | +3 | Mejora de Característica                  |4||3||—||—||—|
| 9  | +4 | —                                                       |4||3||2||—||—|
| 10 | +4 | Aura de Coraje                                          |4||3||2||—||—|
| 11 | +4 | Golpe del Cruzado Mejorado                              |4||3||3||—||—|
| 12 | +4 | Mejora de Característica                  |4||3||3||—||—|
| 13 | +5 | —                                                       |4||3||3||1||—|
| 14 | +5 | Toque Purificador                                       |4||3||3||1||—|
| 15 | +5 | Rasgo de Camino Sagrado                                 |4||3||3||2||—|
| 16 | +5 | Mejora de Característica                  |4||3||3||2||—|
| 17 | +6 | —                                                       |4||3||3||3||1|
| 18 | +6 | Mejoras de Aura                                         |4||3||3||3||1|
| 19 | +6 | Mejora de Característica                  |4||3||3||3||2|
| 20 | +6 | Rasgo de Camino Sagrado                                 |4||3||3||3||2|
</div>

&nbsp;&nbsp;&nbsp; ¿Cómo experimentaste tu llamada para ser paladín? ¿Escuchaste un susurro de la Luz mientras orabas? ¿Otro paladín percibió tu potencial y te entrenó como escudero? ¿O fue un evento terrible lo que te impulsó a actuar? Tal vez encontraste un bosque sagrado o un enclave élfico oculto y sentiste el deber de proteger esos refugios de bondad y belleza. O quizás siempre supiste, desde tus primeros recuerdos, que la vida de paladín era tu destino.

Como guardianes contra el mal, los paladines rara vez tienen un alineamiento malvado; la mayoría sigue los caminos de la caridad y la justicia.

#### Multiclase

***Característica Mínima.*** Debes tener al menos 13 de Fuerza y Carisma para coger un nivel en esta clase, o para coger un nivel en otra clase si ya eres un paladín.

***Competencias Obtenidas.*** Armaduras ligeras, armaduras medianas, escudos, armas simples, armas marciales.

***Ranuras de Hechizo.*** Suma la mitad de tus niveles de paladin (redondeando hacia arriba) a los niveles apropiados de otras clases para determinar tu mana.

#### Creación Rápida
Haz que tu puntuación de característica más alta debe ser Fuerza, seguida de Carisma. (Los sanadores suelen priorizar Constitución por encima de Fuerza).

## Rasgos de Clase

#### Puntos de Golpe
___
- **Dados de Golpe:** 1d10 por nivel de paladín
- **PG al 1:** 10 + Mod. Constitución
- **PG por nivel:** 1d10 (o 6) + Mod. Constitución por cada nivel de paladín

#### Competencias
___
- **Armaduras:** Todas las armaduras, escudos
- **Armas:** Armas simples, armas marciales
- **Herramientas:** Ninguna
- **Tiradas de Salvación:** Sabiduría, Carisma
- **Habilidades:** Elige dos entre Atletismo, Perspicacia, Intimidación, Medicina, Persuasión y Religión
- 
#### Equipo
Comienzas con el siguiente equipo, además del equipo otorgado por tu trasfondo:
 - *(a)* un arma marcial y un escudo o *(b)* dos armas marciales
 - *(a)* un paquete de sacerdote o *(b)* un paquete de explorador
 - Cota de malla y un símbolo sagrado

<div class='footnote'>PARTE 1 | CLASES</div>

\pagebreakNum

### Sentido Divino
La presencia de un mal poderoso se registra en tus sentidos como un hedor nocivo, y el bien poderoso resuena como música celestial en tus oídos. Como acción, puedes abrir tu percepción para detectar tales fuerzas. Hasta el final de tu siguiente turno, conoces la ubicación de cualquier celestial, infernal o no-muerto en un radio de 60 pies que no esté bajo cobertura total. Conoces el tipo (celestial, infernal o no-muerto) de cualquier ser cuya presencia detectes, pero no su identidad (como el demonio Illidan Tempestira, por ejemplo). Dentro del mismo radio, también detectas la presencia de cualquier lugar u objeto que haya sido consagrado o profanado, como con el hechizo *santuario*.

Puedes usar esta característica un número de veces igual a 1 + tu modificador de Carisma. Cuando terminas un descanso largo, recuperas todos los usos gastados.

### Imposición de Manos
Tu toque bendito puede curar heridas. Tienes una reserva de poder curativo que se repone cuando tomas un descanso largo. Con esa reserva, puedes restaurar un número total de puntos de golpe igual a tu nivel de paladín x 5.

Como acción, puedes tocar a una criatura y extraer poder de la reserva para restaurar un número de puntos de golpe a esa criatura, hasta la cantidad máxima que quede en tu reserva.

Alternativamente, puedes gastar 5 puntos de golpe de tu reserva de curación para curar al objetivo de una enfermedad o neutralizar un veneno que lo esté afectando. Puedes curar múltiples enfermedades y neutralizar múltiples venenos con un solo uso de Imposición de Manos, gastando puntos de golpe por separado para cada uno.

Esta característica no tiene efecto en muertos vivientes y constructos.

### Estilo de Combate
En el 2º nivel, adoptas un estilo de lucha como tu especialidad. Elige una de las siguientes opciones. No puedes tomar una opción de Estilo de Combate más de una vez, incluso si más adelante tienes la posibilidad de elegir nuevamente.

#### Guerrero Bendito
Aprendes dos trucos de tu elección de la lista de conjuros de sacerdote. Cuentan como conjuros de paladín para ti, y el Carisma es tu habilidad de lanzamiento de conjuros para ellos. Siempre que ganes un nivel en esta clase, puedes reemplazar uno de estos trucos por otro truco de la lista de sacerdote.

#### Defensa
Mientras lleves armadura, ganas un bono de +1 a tu CA.

#### Doble Empuñadura
Cuando empuñas un arma cuerpo a cuerpo en una mano y no tienes otras armas, ganas un bono de +2 a las tiradas de daño con esa arma.

\columnbreak

#### Gran Arma
Cuando sacas un 1 o un 2 en el dado de daño de un ataque que haces con un arma cuerpo a cuerpo que estés empuñando con ambas manos, puedes volver a tirar el dado y debes usar el nuevo resultado. El arma debe tener la propiedad de dos manos o versátil para que obtengas este beneficio.

#### Protección
Cuando una criatura que puedas ver ataque a un objetivo que no seas tú y esté a 5 pies de ti, puedes usar tu reacción para imponer desventaja en la tirada de ataque. Debes estar empuñando un escudo.

### Lanzamiento de Conjuros
A partir del 2º nivel, has aprendido a extraer magia divina mediante la meditación y la oración para lanzar conjuros como un sacerdote. Consulta el capítulo 10 del *Manual del Jugador* para las reglas generales sobre el lanzamiento de conjuros y el capítulo 6 de este libro para la lista de conjuros del paladín.

#### Preparar y Lanzar Conjuros
La tabla del Paladín muestra cuántas ranuras de conjuro tienes para lanzar tus conjuros. Para lanzar uno de tus conjuros de paladín de 1er nivel o superior, debes gastar una ranura de conjuro del nivel del conjuro o superior. Recuperas todas las ranuras de conjuro gastadas cuando terminas un descanso largo.

Preparas la lista de conjuros de paladín que están disponibles para que los lances, eligiendo de la lista de conjuros de paladín. Cuando lo haces, elige un número de conjuros de paladín igual a tu modificador de Carisma + la mitad de tu nivel de paladín, redondeado hacia abajo (mínimo de un conjuro). Los conjuros deben ser de un nivel para el cual tengas ranuras de conjuro.

Por ejemplo, si eres un paladín de 5º nivel, tienes cuatro ranuras de conjuro de 1er nivel y dos de 2º nivel. Con un Carisma de 14, tu lista de conjuros preparados puede incluir cuatro conjuros de 1er o 2º nivel, en cualquier combinación. Si preparas el conjuro de 1er nivel *curar heridas*, puedes lanzarlo usando una ranura de 1er nivel o de 2º nivel. Lanzar el conjuro no lo elimina de tu lista de preparados.

Puedes cambiar tu lista de conjuros preparados cuando termines un descanso largo. Preparar una nueva lista de conjuros de paladín requiere tiempo dedicado a la oración y la meditación: al menos 1 minuto por nivel de conjuro para cada conjuro en tu lista.

#### Habilidad para Lanzar Conjuros
El Carisma es tu habilidad de lanzamiento de conjuros para tus conjuros de paladín, ya que su poder proviene de la fuerza de tus convicciones. Usas tu Carisma siempre que un conjuro se refiera a tu habilidad para lanzarlo. Además, usas tu modificador de Carisma para establecer la CD de salvación contra tus conjuros de paladín y cuando hagas una tirada de ataque con uno.

<div style="text-align: Center">

**CD de Salvación de Conjuro** =<br> 8 + Bonus competencia + Mod. Carisma

**Modificador de Ataque con Conjuros** =<br> Bonus competencia + Mod. Carisma
</div>

<div class='footnote'>PARTE 1 | CLASES</div>

\pagebreakNum

#### Enfoque para Conjuros
Puedes usar un símbolo sagrado como enfoque para lanzar tus conjuros de paladín. Además de los símbolos sagrados presentes en el *Manual del Jugador*, puedes usar un libram como tu símbolo sagrado; un libram cuesta 5 po y pesa 3 lb.

### Golpe del Cruzado
A partir del 2º nivel, cuando golpeas a una criatura con un ataque cuerpo a cuerpo, puedes gastar una ranura de conjuro para infligir daño radiante al objetivo, además del daño del arma. El daño adicional es de 2d8 por una ranura de conjuro de 1er nivel, más 1d8 por cada nivel de conjuro superior a 1º, hasta un máximo de 6d8. El daño de Golpe del Cruzado aumenta en 1d8 si el objetivo es un no-muerto o un infernal.

### Camino Sagrado
Cuando alcanzas el 3er nivel, comienzas un camino sagrado dentro de la iglesia. Elige el Camino de lo Sagrado, el Camino de la Protección o el Camino de la Retribución, todos detallados al final de la descripción de la clase.

Tu elección te otorga características en el 3er nivel y nuevamente en el 7º, 15º y 20º nivel. Estas características incluyen conjuros de camino y la característica Canalizar Divinidad.
<div style='margin-top:-3px;'></div>

#### Conjuros de Camino
Cada camino tiene una lista de conjuros asociados que se escriben en tu libram en los niveles especificados en la descripción del camino. Una vez que un conjuro de camino ha sido escrito en tu libram, siempre lo tienes preparado. Los conjuros de camino no cuentan contra el número de conjuros que puedes preparar cada día.

Si adquieres un conjuro de camino que no aparece en la lista de conjuros de paladín, el conjuro aún así es considerado un conjuro de paladín para ti.
<div style='margin-top:-3px;'></div>

#### Canalizar Divinidad
Tu camino te permite canalizar energía divina para alimentar efectos mágicos. Cada opción de Canalizar Divinidad proporcionada por tu camino explica cómo usarla.

Cuando usas tu Canalizar Divinidad, eliges qué opción usar. Luego debes terminar un descanso corto o largo para usar Canalizar Divinidad de nuevo.

Algunos efectos de Canalizar Divinidad requieren tiradas de salvación. Cuando usas dicho efecto de esta clase, la CD es igual a la CD de salvación de conjuros de tu paladín.
<div style='margin-top:-3px;'></div>

### Mejora de Caracteristica
Cuando alcanzas el 4º nivel, y nuevamente en el 8º, 12º, 16º y 19º nivel, puedes aumentar una puntuación de habilidad de tu elección en 2, o puedes aumentar dos puntuaciones de habilidad de tu elección en 1. Como es habitual, no puedes aumentar una puntuación de habilidad por encima de 20 con esta característica.
<div style='margin-top:-3px;'></div>

### Ataque Extra
A partir del 5º nivel, puedes atacar dos veces, en lugar de una, siempre que realices la acción de Ataque en tu turno.

\columnbreak

<div style='margin-top:-3px;'></div>

### Aura de Protección
A partir del 6º nivel, siempre que tú o una criatura aliada dentro de 10 pies de ti deba hacer una tirada de salvación, la criatura gana un bono a la tirada de salvación igual a tu modificador de Carisma (con un bono mínimo de +1). Debes estar consciente para otorgar este bono.

En el nivel 18, el alcance de esta aura aumenta a 30 pies.
<div style='margin-top:-3px;'></div>

### Aura de Coraje
A partir del 10º nivel, tú y las criaturas aliadas dentro de 10 pies de ti no pueden ser asustadas mientras estés consciente.

En el nivel 18, el alcance de esta aura aumenta a 30 pies.
<div style='margin-top:-3px;'></div>

### Golpe del Cruzado Mejorado
En el 11º nivel, estás tan imbuido por la luz sagrada que todos tus ataques con armas cuerpo a cuerpo llevan poder divino. Siempre que golpees a una criatura con un arma cuerpo a cuerpo, la criatura recibe un daño radiante adicional de 1d8.
<div style='margin-top:-3px;'></div>

### Toque Purificador
A partir del 14º nivel, puedes usar tu acción para terminar un conjuro en ti mismo o en una criatura voluntaria que toques.

Puedes usar esta característica un número de veces igual a tu modificador de Carisma (mínimo una vez). Recuperas los usos gastados cuando terminas un descanso largo.

\pagebreakNum

## Camino Sagrado
Convertirse en un paladín implica hacer votos de compromiso con la causa de la justicia, un viaje activo por el camino de luchar contra las fuerzas malignas de Azeroth. Muchos guerreros no se consideran verdaderos paladines hasta que han dado el primer paso en su camino sagrado. El camino que elijas refleja tus prioridades como paladín.

### Camino de lo Sagrado
Al igual que los sacerdotes que sirven a la Luz, los paladines sagrados son devotos en su fe. Después de pasar gran parte de sus vidas en salas consagradas estudiando doctrina divina, aquellos que se comprometen a una orden sagrada se convierten en faros de la Luz para sus aliados en conflicto, tomando la armadura pesada y el armamento de la justicia. La verdad y la virtud de la Luz impregnan a estos caballeros sagrados con el poder de revitalizar a sus camaradas.

#### Conjuros de Camino
Obtienes conjuros de camino en los niveles de paladín indicados.

##### Conjuros del Camino de lo Sagrado
| Nivel de Paladín | Conjuros                                 |
|:----:|:-------------------------------------------|
| 3º   | *protección contra el bien y el mal, ✦ penitencia* |
| 5º   | *✦ prisma sagrado, restauración menor*     |
| 9º   | *farol de esperanza, revivir*              |
| 13º  | *✦ escudo divino, guardián de la fe*       |
| 17º  | *arma sagrada, curar heridas masivas*      |
<div style='margin-top:-5px;'></div>

*✦ Nuevos conjuros se pueden encontrar en el capítulo 6 más adelante en este libro* 

\columnbreak

#### Canalizar Divinidad
Cuando tomas este camino al 3er nivel, obtienes las siguientes dos opciones de Canalizar Divinidad.

***Luz del Amanecer.*** Puedes usar tu Canalizar Divinidad para disipar la oscuridad y curar a aliados heridos. Como acción, disipas cualquier oscuridad mágica en un cono de 30 pies frente a ti y evocas energía curativa que puede restaurar un número de puntos de golpe igual a cinco veces tu nivel de paladín a las criaturas. Elige cualquier criatura dentro del cono y divide esos puntos de golpe entre ellas. No puedes usar esta característica en un no-muerto o un constructo.

***Martillo de Luz.*** Como acción, golpeas el suelo con un martillo divino en un espacio dentro de 30 pies de ti, haciendo que estalle con luz sagrada en un radio de 5 pies alrededor de él. Cada criatura de tu elección dentro del alcance debe hacer una tirada de salvación de Constitución, recibiendo daño radiante igual a 2d10 + tu nivel de paladín si falla, o la mitad de daño si tiene éxito.


#### Destello de Luz
En el 3er nivel, puedes usar tu acción adicional y gastar una ranura de conjuro para restaurar puntos de golpe a un objetivo dentro de 20 pies de ti. Restauras un número de puntos de golpe igual a 2d6 por una ranura de conjuro de 1er nivel, más 1d6 por cada nivel de conjuro superior al 1º, hasta un máximo de 6d6.

Esta característica no tiene efecto en no-muertos o constructos.

#### Aura de Devoción
A partir del 7º nivel, tú y las criaturas aliadas dentro de 10 pies de ti no pueden ser encantadas mientras estés consciente.

En el nivel 18, el alcance de esta aura aumenta a 30 pies.

#### Espíritu Inquebrantable
A partir del nivel 15, cuando tus puntos de golpe se reducen a 0 y no mueres al instante, puedes optar por reducirte a 1 punto de golpe en su lugar. Una vez que uses esta habilidad, no podrás volver a usarla hasta que termines un descanso largo.

#### Propósito Divino
En el nivel 20, cuando normalmente tirarías uno o más dados para restaurar puntos de golpe con un conjuro, en su lugar usas el número más alto posible para cada dado. Por ejemplo, en lugar de restaurar 2d6 puntos de golpe a una criatura, restauras 12.

<img src='https://i.ibb.co/wwWsr0j/Paladin-Holy.png' style='position:absolute; top:800px; right:-50px; width:950px' />
<img src='https://www.gmbinder.com/images/3e9S91s.png' style='position:absolute; top:-110px; right:0px; width:820px' />

<div class='footnote'>PARTE 1 | CLASES</div>

\pagebreakNum

### Camino de la Protección
Firme e imperturbable, los paladines del Camino de la Protección son defensores ardientes de la Luz y todo lo que toca, y son rejuvenecidos por su resplandor a cambio. Su dedicación a la causa es tal que consagran el mismo suelo sobre el que luchan contra la corrupción.

#### Conjuros de Camino
Obtienes conjuros de camino en los niveles de paladín indicados.

##### Conjuros del Camino de la Protección
| Nivel de Paladín | Conjuros                             |
|:----:|:-----------------------------------------|
| 3º   | *santuario, escudo de la fe*             |
| 5º   | *castigo deslumbrante, ✦ guardián del rey* |
| 9º   | *aura de vitalidad, ✦ luz cegadora*     |
| 13º  | *aura de pureza, protección contra la muerte*  |
| 17º  | *consagrar, ✦ luz del protector*         |
<div style='margin-top:-5px;'></div>

*✦ Los nuevos conjuros pueden encontrarse en el capítulo 6 más adelante en este libro* 

#### Canalizar Divinidad
Cuando tomas este camino al 3er nivel, obtienes las siguientes dos opciones de Canalizar Divinidad.

***Consagración.*** Como acción, puedes usar tu Canalizar Divinidad para consagrar el suelo a tu alrededor en un radio de 30 pies. Cada criatura de tu elección dentro del rango debe realizar una tirada de salvación de Destreza, recibiendo daño radiante igual a tu nivel de paladín + tu modificador de Carisma en una tirada fallida, o la mitad del daño en una exitosa. Además, cada criatura aliada dentro del rango gana un número de puntos de golpe temporales igual a la mitad de tu nivel de paladín + tu modificador de Carisma.

***Escudo Sagrado.*** Como acción adicional, invocas la luz para protegerte. Durante 1 minuto, las tiradas de ataque contra ti se realizan con desventaja. Además, una vez por turno, cuando una criatura falle un ataque cuerpo a cuerpo contra ti, puedes infligirle daño radiante igual a 1d6 más la mitad de tu nivel de paladín.

#### Bastión Divino
En el nivel 3, cuando golpeas a una criatura con un ataque cuerpo a cuerpo, puedes gastar una ranura de conjuro para infligir daño radiante al objetivo, además del daño del arma. El daño adicional es de 2d6 por una ranura de conjuro de 1er nivel, más 1d6 por cada nivel de conjuro superior al 1º, hasta un máximo de 6d6.

Además, la criatura tiene desventaja en las tiradas de ataque contra criaturas que no seas tú hasta el final de tu próximo turno. Por cada nivel de conjuro superior al 1º, puedes elegir una criatura adicional dentro de 10 pies de ti para que sufra este efecto hasta el final de tu próximo turno.

Un ataque cuerpo a cuerpo puede beneficiarse de tu Golpe del Cruzado o de tu Bastión Divino, pero solo uno de estos efectos puede aplicarse a un ataque.

\columnbreak

#### Aura del Guardián
A partir del nivel 7, cuando una criatura a 10 pies de ti recibe daño, puedes usar tu reacción para tomar mágicamente ese daño en lugar de que lo reciba la criatura. Esta característica no transfiere ningún otro efecto que pueda acompañar el daño, y este daño no puede ser reducido de ninguna manera.

A nivel 18, el alcance de esta aura aumenta a 30 pies.

#### Protección Justa
A partir del nivel 15, siempre estás bajo los efectos de un conjuro de *protección contra el mal y el bien*.

#### Defensor Ardiente
A nivel 20, tu armadura es reemplazada por placas pesadas de energía divina, y tu presencia en el campo de batalla se convierte en una inspiración para quienes te rodean. Usando tu acción, experimentas una transformación. Durante 1 minuto, obtienes los siguientes beneficios:
 - Tienes resistencia al daño contundente, perforante y cortante de armas no mágicas.
 - Tus aliados tienen ventaja en las tiradas de salvación contra la muerte mientras estén a 30 pies de ti.
 - Tienes ventaja en las tiradas de salvación de Sabiduría, al igual que tus aliados a 30 pies de ti.
<div style='margin-top:-5px;'></div>

&nbsp;&nbsp;&nbsp; Este efecto termina temprano si estás incapacitado o mueres. Una vez que uses esta característica, no podrás volver a usarla hasta que termines un descanso largo.

<div class='footnote'>PARTE 1 | CLASES</div>

<img src='https://www.gmbinder.com/images/GRPZRQ3.jpg' style='position:absolute; top:270px; right:-180px; width:740px' />
<img src='https://www.gmbinder.com/images/wvTUmvu.png' style='position:absolute; top:-10px; right:0px; width:800px' />
<img src='https://www.gmbinder.com/images/E8GrMME.png' style='position:absolute; top:0px; right:0px; width:900px' />

\pagebreakNum

### Camino de la Retribución
Los paladines dedicados se vuelven fanáticos en su devoción, instrumentos de retribución contra aquellos que se atreven a desafiar las leyes divinas. Cruzados que juzgan y castigan a los malvados. Su convicción inquebrantable en el orden divino de todas las cosas les asegura que la victoria es inevitable.

#### Conjuros de Camino
Obtienes conjuros de camino en los niveles de paladín indicados.

##### Conjuros del Camino de la Retribución
| Nivel de Paladín | Conjuros                              |
|:----:|:-----------------------------------------|
| 3º   | *duelo forzado, castigo abrasador*      |
| 5º   | *arma mágica, ✦ castigo justo*                |
| 9º   | *castigo cegador, ✦ ira sagrada*           |
| 13º  | *✦ escudo divino, castigo tambaleante*   |
| 17º  | *onda destructiva, disipar el mal y el bien* |
<div style='margin-top:-5px;'></div>

*✦ Los nuevos conjuros pueden encontrarse en el capítulo 6 más adelante en este libro* 

#### Canalizar Divinidad
Cuando tomas este camino al 3er nivel, obtienes las siguientes dos opciones de Canalizar Divinidad.

&nbsp;&nbsp;&nbsp; ***Veredicto del Templario.*** Como acción adicional, puedes emitir un veredicto contra una criatura que puedas ver a 10 pies de ti. Obtienes ventaja en las tiradas de ataque contra la criatura durante 1 minuto, hasta que caiga a 0 puntos de golpe o quede inconsciente.

***Rechazar lo Profano.*** Como acción, presentas tu símbolo sagrado y pronuncias una oración censurando a demonios y no muertos, usando tu Canalizar Divinidad. Cada demonio o no muerto que pueda verte o escucharte a 30 pies debe hacer una tirada de salvación de Sabiduría. Si falla, queda apartado durante 1 minuto o hasta que reciba daño.

Una criatura apartada debe gastar sus turnos intentando alejarse lo más posible de ti, y no puede acercarse voluntariamente a un espacio a 30 pies de ti. Tampoco puede realizar reacciones. Para su acción, solo puede usar la acción de Correr o intentar escapar de un efecto que le impida moverse. Si no hay adónde moverse, puede usar la acción de Esquivar.

\columnbreak

#### Tormenta Divina
A nivel 3, cuando golpeas a una criatura con un ataque cuerpo a cuerpo, puedes gastar una ranura de conjuro para infligir daño radiante al objetivo y a todas las criaturas a 5 pies de ti, además del daño del arma. Una criatura puede hacer una tirada de salvación de Destreza, recibiendo la mitad del daño si tiene éxito. El daño adicional es de 2d6 por una ranura de conjuro de 1er nivel, más 1d6 por cada nivel de conjuro superior al 1º, hasta un máximo de 6d6.

Un ataque cuerpo a cuerpo puede beneficiarse de tu Golpe del Cruzado o de tu Tormenta Divina, pero solo uno de estos efectos puede aplicarse a un ataque.

#### Aura del Cruzado
A partir del nivel 7, emites un aura de alerta mientras no estés incapacitado. Cuando tú y las criaturas aliadas dentro de 10 pies de ti tiran iniciativa, cada una obtiene un bono igual a tu modificador de Carisma (mínimo de +1).

A nivel 18, el alcance de esta aura aumenta a 30 pies.

#### Ojo por Ojo
A partir del nivel 15, cuando una criatura bajo el efecto de tu Veredicto del Templario hace un ataque, puedes usar tu reacción para hacer un ataque cuerpo a cuerpo contra la criatura si está a tu alcance.

#### Ira Vengativa
A nivel 20, asumes la forma de un campeón imponente de la Luz. Usando tu acción, experimentas una transformación. Durante 1 hora, obtienes los siguientes beneficios:
 - Alas brotan de tu espalda y te otorgan una velocidad de vuelo de 60 pies.
 - Emanas un aura de amenaza en un radio de 30 pies. La primera vez que un enemigo entra en el aura o comienza su turno allí durante una batalla, debe hacer una tirada de salvación de Sabiduría o quedar aterrorizado de ti durante 1 minuto o hasta que reciba daño. Las tiradas de ataque contra la criatura aterrorizada tienen ventaja.
<div style='margin-top:-5px;'></div>

&nbsp;&nbsp;&nbsp; Una vez que uses esta característica, no podrás volver a usarla hasta que termines un descanso largo.

<img src='https://www.gmbinder.com/images/64RBMik.jpg' style='position:absolute; top:800px; right:-150px; width:950px' />
<img src='https://www.gmbinder.com/images/3e9S91s.png' style='position:absolute; top:-120px; right:0px; width:820px' />

<div class='footnote'>PARTE 1 | CLASES</div>

\pagebreakNum

<div style='margin-top:370px;'></div>

## Sacerdote
*Es la fe en nosotros mismos la que nos separa de los demás, y con nuestros poderes, causaremos grandes cambios en todo Azeroth. Los débiles vendrán a apoyarse en ti. Los leprosos te llamarán Señor. Y los ignorantes buscarán tu guía.*
<div style="text-align:Right"> 

*— Clérigo Oscuro Duesten* &nbsp;</div>

Arrodillada sobre su aliado caído, una enana empuña su símbolo sagrado y entona una melodía lenta. La Luz brilla en su mano, cubriendo el cuerpo de su compañero.

Arrodillado, con una mano firmemente sosteniendo un bastón y la otra llena de energías divinas y necróticas, un humano se levanta y emite un halo de luz y oscuridad a su alrededor: sus aliados recuperan vida mientras sus enemigos sienten el poder necrótico recorrer sus cuerpos.

Un renegado, envuelto en energía del vacío, saca su símbolo sagrado mientras tentáculos brotan de su espalda y ríe, lanzando ráfagas de energía necrótica contra enemigos y aliados.

Los sacerdotes son el puente entre la luz y la oscuridad, portadores de la cálida luz divina y de la magia del vacío otorgada por los dioses antiguos. Actúan como protectores, sanadores y emisores de locura.

### Invocadores de Luz y Oscuridad
Los sacerdotes son devotos de lo espiritual y expresan su fe sirviendo a los demás. Durante milenios, han dejado los confines de sus templos y la comodidad de sus santuarios para apoyar a sus aliados en tierras desgarradas por la guerra. En medio del conflicto, el valor de los sacerdotes nunca es cuestionado. Estos maestros de las artes curativas mantienen a sus compañeros luchando mucho más allá de sus capacidades mediante poderes restaurativos y bendiciones. Las fuerzas divinas al mando del sacerdote también se pueden usar contra los enemigos.

Así como la luz no puede existir sin la oscuridad, algunos sacerdotes recurren a las sombras para comprender mejor sus propias habilidades, así como las de aquellos que los amenazan.

\columnbreak

<div style='margin-top:522px;'></div>

### Acólitos Devotos
Los sacerdotes practican una forma compleja y organizada de espiritualidad basada en la filosofía moral, la adoración de una deidad, y/o el culto a ídolos, en contraste con la veneración de los elementos de los chamanes o la conexión divina con la naturaleza de los druidas. Los sacerdotes son figuras religiosas influyentes en sus sociedades y poderosos practicantes de magia divina, que utilizan para sanar y proteger o para dañar y debilitar.

La devoción a las creencias de Azeroth lleva a muchos sacerdotes a los caminos del coraje y la heroísmo. En tiempos oscuros, los sacerdotes llevan la luz de la fe como recordatorio de las poderosas fuerzas que operan más allá de la comprensión de los pueblos que caminan por la tierra. Poderosos sanadores con una conexión íntima con lo divino, los sacerdotes están empoderados con habilidades que los ayudan en momentos de necesidad extrema.

### Creando un Sacerdote
¿Eres un servidor devoto del bien, leal a la luz sagrada? ¿Un sacerdote disciplinado, en bellas túnicas, que vigila un septo? ¿O eres un sacerdote impío de las sombras, caído ya sea por elección o forzado hacia las artes necróticas?

¿Cómo entraste al sacerdocio? ¿Fuiste criado en un monasterio? ¿Escuchaste un susurro de la luz misma pidiéndote que la sirvas? ¿O una terrible guerra te obligó a tomar la calidez de la luz sagrada para asistir a tus aliados? Quizás supiste desde tus primeros recuerdos que la vida del sacerdote era tu llamado, casi como si hubieras sido enviado al mundo con ese propósito marcado en tu alma.

<div class='footnote'>PARTE 1 | CLASES</div>

<img src='https://www.gmbinder.com/images/ydhgeyS.jpg' style='position:absolute; top:0px; right:0px; width:800px' />
<img src='https://www.gmbinder.com/images/vn90cy3.png' style='position:absolute; top:0px; right:-100px; width:900px' />
<img src='https://www.gmbinder.com/images/lyv4YVJ.png' style='position:absolute; top:-130px; right:-100px; width:600px' />

\pagebreakNum

<div class='classTable wide'>

##### El Sacerdote
|Nivel|Bonificador de<br>Competencia|Puntos<br>de Fe|&nbsp;|Características|Conjuros<br>Conocidos|&nbsp;|1°|&nbsp;|2°|&nbsp;|3°|&nbsp;|4°|&nbsp;|5°|&nbsp;|6°|&nbsp;|7°|&nbsp;|8°|&nbsp;|9° <div style="position: absolute; top:100px; right:101px; width:200px; height:25px">—Ranuras de Conjuro por Nivel—</div>|
|:---:|:--:|:-:|-|:-----------------------|:-:|-|:-:|-|:-:|-|:-:|-|:-:|-|:-:|-|:-:|-|:-:|-|:-:|-|:-:|
| 1ro | +2  | —|| Lanzamiento de Conjuros, Llamado Divino     |3||2||—||—||—||—||—||—||—||—|
| 2do | +2  | 2|| Ecos de Fe                                 |3||3||—||—||—||—||—||—||—||—|
| 3ro | +2  | 3|| Absolución                                |3||4||2||—||—||—||—||—||—||—|
| 4to | +2  | 4|| Mejora de Puntuación de Característica     |4||4||3||—||—||—||—||—||—||—|
| 5to | +3  | 5|| Restauración de los Fieles                |4||4||3||2||—||—||—||—||—||—|
| 6to | +3  | 6|| Característica de Llamado Divino          |4||4||3||3||—||—||—||—||—||—|
| 7mo | +3  | 7|| —                                        |4||4||3||3||1||—||—||—||—||—|
| 8vo | +3  | 8|| Mejora de Puntuación de Característica     |4||4||3||3||2||—||—||—||—||—|
| 9no | +4  | 9|| —                                        |4||4||3||3||3||1||—||—||—||—|
| 10mo| +4  |10|| Mejora de la Restauración de los Fieles   |5||4||3||3||3||2||—||—||—||—|
| 11vo| +4  |11|| —                                        |5||4||3||3||3||2||1||—||—||—|
| 12vo| +4  |12|| Mejora de Puntuación de Característica     |5||4||3||3||3||2||1||—||—||—|
| 13vo| +5  |13|| —                                        |5||4||3||3||3||2||1||1||—||—|
| 14vo| +5  |14|| Característica de Llamado Divino          |5||4||3||3||3||2||1||1||—||—|
| 15vo| +5  |15|| —                                        |5||4||3||3||3||2||1||1||1||—|
| 16vo| +5  |16|| Mejora de Puntuación de Característica     |5||4||3||3||3||2||1||1||1||—|
| 17vo| +6  |17|| Mejora de la Restauración de los Fieles   |5||4||3||3||3||2||1||1||1||1|
| 18vo| +6  |18|| —                                        |5||4||3||3||3||3||1||1||1||1|
| 19vo| +6  |19|| Mejora de Puntuación de Característica     |5||4||3||3||3||3||2||1||1||1|
| 20vo| +6  |20|| Característica de Llamado Divino          |5||4||3||3||3||3||2||2||1||1|
</div>

&nbsp;&nbsp;&nbsp; Como guardianes contra las fuerzas de la maldad y el mal, los sacerdotes rara vez tienen alineamientos malignos. La mayoría de ellos caminan por los caminos de la caridad y la tranquilidad, o ¿nunca sentiste la calidez de la luz sagrada y en su lugar fuiste llamado por los dioses antiguos? ¿Su magia del vacío envolviéndote y volviendo caóticas tus acciones?

#### Creación Rápida
Puedes crear un sacerdote rápidamente siguiendo estas sugerencias. Primero, tu puntuación más alta debería ser Carisma, seguido de Constitución.

#### Multiclase

***Característica Minima.*** Debes tener al menos una puntuación de Carisma de 13 para tomar un nivel en esta clase, o para tomar un nivel en otra clase si ya eres sacerdote.

***Competencias Obtenidas.*** Una habilidad de la lista de habilidades de la clase.

***Ranuras de Conjuro.*** Suma tus niveles en la clase de sacerdote a los niveles apropiados de otras clases para determinar tus ranuras de conjuro disponibles.

\columnbreak

## Rasgos de Clase

#### Puntos de Golpe
___
- **Dados de Golpe:** 1d6 por nivel de sacerdote
- **PG al 1:** 6 + Mod. Constitución
- **PG por Nivel:** 1d6 (o 4) + Mod. Constitución por cada nivel de sacerdote

#### Competencias
___
- **Armadura:** Ninguna
- **Armas:** Todas las armas simples
- **Herramientas:** Kit de herboristería
- **Tiradas de Salvación:** Sabiduría, Carisma
- **Habilidades:** Elige dos entre Historia, Perspicacia, Medicina, Persuasión y Religión

#### Equipo
Comienzas con el siguiente equipo, además del equipo concedido por tu trasfondo:
 - *(a)* una maza o *(b)* un bastón
 - *(a)* un paquete de sacerdote o *(b)* un paquete de explorador
 - un símbolo sagrado, kit de herboristería y dos dagas

<div class='footnote'>PARTE 1 | CLASES</div>


\pagebreakNum

<div style='margin-top:160px;'></div>

### Lanzamiento de Conjuros
Como un canal para el poder divino, puedes lanzar conjuros de sacerdote. Consulta el capítulo 10 del Manual del Jugador para conocer las reglas generales sobre el lanzamiento de conjuros y el capítulo 6 de este libro para la lista de conjuros de sacerdote.

#### Trucos
Al nivel 1, conoces tres trucos de tu elección de la lista de conjuros de sacerdote. Aprendes trucos adicionales de sacerdote de tu elección en niveles superiores, como se muestra en la columna de Trucos de la tabla del Sacerdote.

#### Preparación y Lanzamiento de Conjuros
La tabla del Sacerdote muestra cuántas ranuras de conjuro tienes para lanzar tus conjuros de 1er nivel y superiores. Para lanzar uno de estos conjuros, debes gastar una ranura de conjuro del nivel del conjuro o superior. Recuperas todas las ranuras de conjuro gastadas cuando terminas un descanso largo.

Preparas la lista de conjuros de sacerdote que están disponibles para que los lances, eligiendo de la lista de conjuros de sacerdote. Al hacerlo, elige un número de conjuros de sacerdote igual a tu modificador de Carisma + tu nivel de sacerdote (mínimo de un conjuro). Los conjuros deben ser de un nivel para el que tengas ranuras de conjuro.

Por ejemplo, si eres un sacerdote de nivel 3, tienes cuatro ranuras de conjuro de 1er nivel y dos de 2do nivel. Con un Carisma de 16, tu lista de conjuros preparados puede incluir seis conjuros de 1er o 2do nivel, en cualquier combinación. Si preparas el conjuro de 1er nivel *curar heridas*, puedes lanzarlo usando una ranura de 1er nivel o 2do nivel. Lanzar el conjuro no lo elimina de tu lista de conjuros preparados.

Puedes cambiar tu lista de conjuros preparados cuando termines un descanso largo. Preparar una nueva lista de conjuros de sacerdote requiere tiempo dedicado a la oración y la meditación: al menos 1 minuto por nivel de conjuro para cada conjuro en tu lista.

#### Habilidad para Lanzar Conjuros
El Carisma es tu habilidad para lanzar conjuros de sacerdote, ya que el poder de tu magia se basa en tu capacidad para proyectar tu voluntad en el mundo. Usas tu Carisma siempre que un conjuro de sacerdote se refiera a tu habilidad para lanzar conjuros. Además, usas tu modificador de Carisma para determinar la CD de salvación de un conjuro de sacerdote que lances y para realizar una tirada de ataque con uno.

<div style="text-align: Center">

**CD de salvación de conjuros** =<br> 8 + Bonus competencia + Mod. Carisma

**Modificador de ataque con conjuros** =<br> Bonus competencia + Mod. Carisma
</div>

\columnbreak

<div style='margin-top:160px;'></div>


#### Lanzamiento de Rituales
Puedes lanzar un conjuro de sacerdote como un ritual si ese conjuro tiene la etiqueta de ritual y lo tienes preparado.

#### Foco para Lanzar Conjuros
Puedes usar un símbolo sagrado como foco para lanzar tus conjuros de sacerdote.

### Llamado Divino
Elige un llamado divino, un camino del sacerdocio al que te has consagrado: Disciplina, Santidad o Sombra. Cada llamado se detalla al final de la descripción de la clase. Tu elección te otorga características cuando lo eliges en el 1er nivel y nuevamente en los niveles 6, 14 y 20.

#### Conjuros del Llamado
Cada llamado tiene una lista de conjuros asociados. Obtienes acceso a estos conjuros en los niveles especificados en la descripción del llamado. Una vez que obtienes acceso a un conjuro del llamado, siempre lo tienes preparado y no cuenta contra la cantidad de conjuros que puedes preparar cada día.

Si obtienes un conjuro del llamado que no aparece en la lista de conjuros de sacerdote, se considera un conjuro de sacerdote para ti.

### Ecos de Fe
En el 2do nivel, la fuerza de tu llamado resuena en ti. Esta fuerza resonante se representa mediante puntos de fe, que te permiten crear una variedad de efectos mágicos.

#### Puntos de Fe
Tienes 2 puntos de fe, y obtienes más a medida que alcanzas niveles superiores, como se muestra en la columna de Puntos de Fe de la tabla del Sacerdote. Nunca puedes tener más puntos de fe que los que se muestran en la tabla para tu nivel. Recuperas todos los puntos de fe gastados cuando terminas un descanso largo.

#### Devoción
Puedes usar tus puntos de fe para obtener ranuras de conjuro adicionales o sacrificar ranuras de conjuro para obtener puntos de fe adicionales. Aprendes otras formas de usar tus puntos de fe a medida que alcanzas niveles superiores.

***Crear Ranuras de Conjuro.*** Puedes transformar puntos de fe no gastados en una ranura de conjuro como acción adicional en tu turno. La tabla de Creación de Ranuras de Conjuro muestra el costo para crear una ranura de conjuro de un nivel determinado. No puedes crear ranuras de conjuro de nivel superior a 5to.

***Convertir una Ranura de Conjuro en Puntos de Fe.*** Como acción adicional en tu turno, puedes gastar una ranura de conjuro y ganar un número de puntos de fe igual al nivel de la ranura.

<div class='footnote'>PARTE 1 | CLASES</div>
<img src='https://wallpapercave.com/wp/wp3333372.jpg' style='position:absolute; top:-50px; right:0px; width:800px' />
<img src='https://www.gmbinder.com/images/3e9S91s.png' style='position:absolute; top:20px; right:0px; width:900px; transform:scaley(-1)' />

\pagebreakNum

##### Creación de Ranuras de Conjuro
| Nivel de Ranura de Conjuro | Costo en Puntos de Fe |
|:----:|:-------:|
| 1  | 2 |
| 2  | 3 |
| 3  | 5 |
| 4  | 6 |
| 5  | 7 |

### Absolución
A partir del 3er nivel, obtienes la capacidad de canalizar tu fe en absoluciones entretejidas con efectos mágicos. Comienzas con dos de estos efectos: Encadenar no-muertos y un efecto determinado por tu llamado.

Algunos efectos de Palabra de Poder requieren tiradas de salvación. Cuando usas uno de estos efectos de esta clase, la CD es igual a la CD de salvación de conjuros de sacerdote.

#### Absolución: Encadenar No-muertos
Como acción, gastas 3 puntos de fe y presentas tu símbolo sagrado. Cada no-muerto que pueda verte o escucharte en un radio de 30 pies debe hacer una tirada de salvación de Sabiduría. Si falla la tirada de salvación, queda aturdido durante 1 minuto o hasta que reciba cualquier daño.

### Mejora de Característica
Cuando alcanzas el nivel 4, y nuevamente en los niveles 8, 12, 16 y 19, puedes aumentar una característica en 2, o puedes aumentar 2 características en 1. No puedes aumentar una característica por encima de 20 usando esta característica.

### Restauración Fiel
A partir del 5º nivel, recuperas 2 puntos de fe siempre que termines un descanso corto. 

El número de puntos de fe que recuperas aumenta a 3 en el 10º nivel y a 4 puntos de fe en el 17º nivel.

## Llamado Divino
Los sacerdotes eligen un llamado divino, un camino del sacerdocio que siguen. Este llamado podría ser la Iglesia de la Luz Sagrada, la diosa Elune, o una secta dedicada a las sombras oscuras y el vacío. Tu elección podría corresponder a una rama particular de los llamados divinos, o simplemente ser una cuestión de preferencia personal, siguiendo el propósito que más te atrae.

### Disciplina
Algunos sacerdotes se enorgullecen de su pragmatismo. Entienden que la luz proyecta sombra, que la oscuridad se define por la luz, y que la verdadera disciplina proviene de la capacidad de equilibrar estos poderes opuestos al servicio de una causa mayor. Aunque estos sacerdotes poseen muchas virtudes santas para ayudar a sus aliados, también se aventuran en las artes oscuras para debilitar a sus enemigos.

\columnbreak

##### Conjuros de Disciplina
| Nivel de Sacerdote | Conjuros               |
|:---:|:------------------------------|
| 1 | curar heridas, infligir heridas |
| 3 | oscuridad, silencio             |
| 5 | ✦ estrella divina, toque vampírico |
| 7 | protección contra la muerte, guardián de la fe |
| 9 | contagio, muro de fuerza        |
<div style='margin-top:-5px;'></div>

*✦ Los nuevos conjuros se pueden encontrar en el capítulo 6 más adelante en este libro* 

#### Truco de Bonificación
A partir del 1er nivel, aprendes un truco adicional de sacerdote de tu elección. Este truco no cuenta contra el número de trucos de sacerdote que conoces.

#### CARACTERISTICA DE 1ER NIVEL
Característica aquí

#### Absolución: Penitencia
A partir del 2º nivel, puedes usar tu Absolución para liberar una expansión de radiancia o fuerza necrótica.

Puedes gastar hasta cinco puntos de fe como acción y lanzar una ráfaga de penitencia hacia un objetivo que puedas ver en un radio de 60 pies. Al hacerlo, eliges si deseas encomendar o condenar a ese objetivo.

***Encomendar.*** El objetivo recupera puntos de golpe iguales a 2 + 1d6 por cada punto de fe gastado. Si esto restaura a la criatura a su máximo de puntos de golpe, gana puntos de golpe temporales iguales al número de puntos de golpe que queden en la reserva.

***Condenar.*** El objetivo recibe daño radiante o necrótico (a tu elección) igual a 1d10 por cada punto de fe gastado, y debe superar una tirada de salvación de Sabiduría o quedar asustado de ti hasta el final de tu siguiente turno.

#### Supresión del Dolor
A partir del 6º nivel, tu mente disciplinada es capaz de proyectar una barrera supresora para la protección de tus aliados.

Como acción adicional, puedes otorgar una barrera a una criatura aliada que puedas ver en un radio de 60 pies. La barrera es invisible. Cualquier daño contundente, perforante o cortante que el objetivo reciba se reduce en 2 + tu bonificador de competencia. Este efecto dura 1 minuto, hasta que lo uses nuevamente o hasta que quedes incapacitado.
<div style='margin-top:-3px;'></div>

#### Castigo
A partir del 14º nivel, cuando lanzas un conjuro que causa daño, elige una criatura dañada por ese conjuro en el turno en que lo lanzaste. Esa criatura recibe daño radiante o necrótico adicional (a tu elección) igual a la mitad de tu nivel de sacerdote. Esta característica solo puede usarse una vez por lanzamiento de un conjuro.

<div class='footnote'>PARTE 1 | CLASES</div>
<img src='https://www.gmbinder.com/images/873nzvm.png' style='position:absolute; top:910px; right:70px; width:300px' />

\pagebreakNum

<div style='margin-top:-3px;'></div>

#### Claridad de Voluntad
En el nivel 20, eres capaz de aprovechar tu voluntad enfocada, mejorando tu Supresión del Dolor. Tu barrera de supresión ahora reduce todo el daño recibido.

Mientras una criatura esté bajo el efecto de tu barrera de supresión, también tiene ventaja en las tiradas de salvación para evitar ser encantada o asustada.
<div style='margin-top:-3px;'></div>

### Sagrado
Los sacerdotes más expertos dejan sus casas de culto para servir en el campo de batalla, como pastores para su rebaño. Allí, utilizan sus poderes sagrados para bendecir a los aliados y curar heridas. Y aunque la mayoría se queda detrás de las líneas del frente para ayudar a sus camaradas, estos campeones sagrados también son capaces de castigar a los enemigos y llevar a cabo la justicia sagrada.
<div style='margin-top:-3px;'></div>

##### Conjuros del Llamado Sagrado
| Nivel de Sacerdote | Conjuros                    |
|:---:|:-----------------------------------------|
| 1º  | bendecir, curar heridas                  |
| 3º  | restauración menor, ✦ fuerza brillante   |
| 5º  | faro de esperanza, revivir               |
| 7º  | protección contra la muerte, adivinación |
| 9º  | curar heridas en masa, levantar a los muertos |
<div style='margin-top:-5px;'></div>

*✦ Los nuevos conjuros se pueden encontrar en el capítulo 6 más adelante en este libro* 

#### Competencia Adicional
Al nivel 1, obtienes competencia en religión si no la tienes y tu bonus de competencia se duplica para cualquier prueba de habilidad que hagas con ella.
<div style='margin-top:-3px;'></div>

#### Himno Divino
Al nivel 1, puedes usar tu acción y presentar tu símbolo sagrado para evocar energía curativa que puede restaurar un número de PG igual a 5 veces tu nivel de sacerdote. Elige cualquier criatura en un radio de 30 pies y divide esos PG entre ellas. Esta característica no puede restaurar a una criatura por encima de la mitad de su máximo de puntos de golpe. No puedes usar esta característica en no-muertos o constructos.

Una vez que usas esta característica, no puedes volver a usarla hasta que completes un descanso corto o largo.
<div style='margin-top:-3px;'></div>

#### Oración de Curación
A partir del 6º nivel, la energía divina de tu fe puede potenciar los conjuros de curación. Siempre que tú o un aliado a 5 pies de ti lancen dados para determinar la cantidad de puntos de golpe que restaura un conjuro, puedes gastar 1 punto de fe para volver a tirar cualquier número de esos dados una vez, siempre que no estés incapacitado. Solo puedes usar esta característica una vez por turno.

<div class='footnote'>PARTE 1 | CLASES</div>
<img src='https://www.gmbinder.com/images/Jeyz36q.jpg' style='position:absolute; top:0px; right:-150px; width:700px; transform:scalex(-1)' />
<img src='https://www.gmbinder.com/images/E8GrMME.png' style='position:absolute; top:0px; right:-20px; width:900px' />

\pagebreakNum

### Nova Sagrada
A partir del nivel 14, cuando recibas un ataque cuerpo a cuerpo, puedes usar tu reacción para infligir daño radiante al atacante. El daño es igual a tu nivel de sacerdote. El atacante debe realizar una tirada de salvación de Fuerza contra la CD de salvación de conjuros de sacerdote. Si falla, es empujado en línea recta hasta 20 pies lejos de ti.

#### Espíritu Guardián
En el nivel 20, puedes invocar un espíritu para guiar a un aliado caído de regreso a su cuerpo. Cuando una criatura a 60 pies de ti muere, puedes usar tu reacción para devolverle la vida antes de que su espíritu parta a las Tierras Sombrías. El objetivo regresa a la vida de inmediato y recupera la mitad de su máximo de puntos de golpe. El objetivo también gana inmunidad contra todo daño hasta el comienzo de su siguiente turno.

Una vez que uses esta característica, no podrás volver a usarla hasta que termines un descanso largo.

### Sombra
La luz más brillante proyecta la sombra más oscura, y dentro de esta oscuridad, habita un poder rival. Los sacerdotes de la sombra abrazan plenamente esta polaridad opuesta, su fe es tan firme como la de sus homólogos sagrados. Al igual que todos los sacerdotes, dedican gran parte de sus vidas al culto, pero derivan su poder del Vacío, acercándose peligrosamente al dominio de los Dioses Antiguos.

##### Conjuros del Llamado de Sombra
| Nivel de Sacerdote | Conjuros                    |
|:---:|:-----------------------------------------|
| 1º  | brazos de hadar, ✦ vacío oscuro          |
| 3º  | ✦ descarga mental, fuerza fantasmal      |
| 5º  | miedo, toque vampírico                   |
| 7º  | tentáculos negros de evard, ✦ cambio del vacío |
| 9º  | drenaje ^XGE^, ✦ choque sombrío          |
<div style='margin-top:-5px;'></div>

*✦ Los nuevos conjuros se pueden encontrar en el capítulo 6 más adelante en este libro* 

#### Voz Psíquica
A partir del nivel 1, puedes penetrar las mentes de otras criaturas. Puedes comunicarte telepáticamente con cualquier criatura que puedas ver a 30 pies de ti. No necesitas compartir un idioma con la criatura para que comprenda tus expresiones telepáticas, pero la criatura debe poder entender al menos un idioma.

\columnbreak

#### Legado del Vacío
También en el nivel 1, cuando infliges daño a una criatura con un cantrip de sacerdote, puedes causar daño psíquico adicional igual a tu modificador de Carisma.

&nbsp;&nbsp;&nbsp; Cuando usas esta característica, debes tener éxito en una tirada de salvación de Sabiduría (CD 10 + 1 por cada uso adicional de esta característica desde tu último descanso largo). Si fallas, no podrás usar esta característica nuevamente hasta que termines un descanso largo.

#### Forma de Sombra
A partir del nivel 6, puedes invocar la corrupción oscura que yace latente en tu interior.

Como acción adicional, puedes cubrirte mágicamente en sombras. Durante 1 minuto, obtienes los siguientes beneficios:
 - Si no llevas armadura, añades tu modificador de Carisma a tu Clase de Armadura.
 - Una criatura que te golpee con un ataque cuerpo a cuerpo o te toque, recibe daño necrótico igual a tu modificador de Carisma.
 - Tus conjuros ignoran la resistencia al daño necrótico y psíquico, y las criaturas inmunes al daño necrótico son consideradas resistentes.

Una vez que uses esta característica, no podrás volver a usarla hasta que termines un descanso corto o largo.

#### Mente Dominante
Al alcanzar el nivel 14, puedes usar tu voz telepática para dominar las mentes de otros. Como acción, puedes gastar 6 puntos de fe para lanzar *dominar bestia* o *dominar persona* sobre una criatura a 30 pies de ti.

Además, tienes ventaja en las tiradas de salvación contra ser encantado.

#### Rendición a la Locura
En el nivel 20, puedes abrazar los susurros locos del vacío y dejar que sus poderes fluyan a través de ti.

Cuando usas tu acción adicional para cubrirte con tu forma de sombra, o como acción adicional mientras está activa, puedes someterte al vacío durante la duración de la forma de sombra y obtener los siguientes beneficios:
 - Cuando normalmente lanzarías uno o más dados de daño por un conjuro de sacerdote de nivel 5 o inferior, en su lugar usas el número más alto posible para cada dado.
 - Puedes usar tu reacción cuando una criatura que puedes ver te ataca o lanza un conjuro contra ti, perforando su mente con los murmullos de los Dioses Antiguos. La criatura debe superar una tirada de salvación de Sabiduría contra tu CD de conjuros o quedar incapacitada hasta el comienzo de tu próximo turno.

Al final de cada uno de tus turnos mientras Rendición a la Locura está activa, debes tener éxito en una tirada de salvación de Sabiduría (CD 10 + 1 por cada salvación exitosa), o recibirás daño psíquico igual a la mitad de tu máximo de puntos de golpe mientras la locura te consume y termina tu forma de sombra.

Una vez que uses esta característica, no podrás volver a usarla hasta que termines un descanso largo.

<div class='footnote'>PARTE 1 | CLASES</div>

<img src='https://www.gmbinder.com/images/dlh3o9V.jpg' style='position:absolute; top:800px; right:300px; width:600px' />

<img src='https://www.gmbinder.com/images/3e9S91s.png' style='position:absolute; top:-55px; right:0px; width:820px' />

<img src='https://www.gmbinder.com/images/E8GrMME.png' style='position:absolute; top:0px; right:-115px; width:900px; transform:scalex(-1)' />

\pagebreakNum

### Palabra de Poder
A partir del nivel 3, eres capaz de pronunciar palabras de poder tejidas con efectos mágicos. Obtienes dos de las siguientes opciones de Palabra de Poder de tu elección. Obtienes otra opción adicional en los niveles 10 y 17.

#### Barrera
Cuando una criatura dentro de 30 pies de ti es golpeada por una tirada de ataque, puedes usar tu reacción y gastar 1 punto de fe para forzar a la criatura a volver a tirar el ataque.

#### Llamada
Puedes usar tu reacción y gastar 2 puntos de fe cuando una criatura aliada dentro de 60 pies de ti se ve obligada a hacer una tirada de salvación para evitar un efecto de área o cae. La criatura es arrastrada a un espacio vacío a 5 pies de ti y no sufre efectos del área si Llamada la sacó de la zona ni recibe daño por caer.

#### Castigo
Usando tu acción, puedes gastar 2 puntos de fe para castigar a una criatura dentro de 30 pies de ti. La criatura debe tener éxito en una tirada de salvación de Sabiduría contra tu CD de salvación de conjuros de sacerdote o quedar incapacitada hasta el final de su próximo turno.

#### Muerte
Cuando tires daño para un conjuro de sacerdote, puedes gastar 1 punto de fe para volver a tirar un número de dados de daño igual a tu modificador de Carisma (mínimo uno). Debes usar los nuevos resultados para esos dados.

#### Fortaleza
Puedes usar tu reacción y gastar 2 puntos de fe para otorgar ventaja en una tirada de salvación a criaturas. Para ello, elige un número de criaturas dentro de 30 pies de ti igual a tu modificador de Carisma (mínimo uno) para que tengan ventaja en la tirada de salvación.

\columnbreak

#### Resplandor
Cuando eres golpeado por un ataque cuerpo a cuerpo, puedes gastar 1 punto de fe como reacción y forzar a la criatura a tener éxito en una tirada de salvación de Sabiduría contra tu CD de salvación de conjuros de sacerdote o quedar asustada de ti hasta el final de su próximo turno.

#### Dolor
Como acción adicional, puedes gastar 1 punto de fe y envolver a una criatura dentro de 60 pies de ti en dolor. La criatura debe tener éxito en una tirada de salvación de Constitución contra tu CD de salvación de conjuros de sacerdote o tendrá desventaja en todas las tiradas de ataque hasta el final de su próximo turno.

#### Escudo
Puedes tocar a una criatura como acción adicional y gastar 2 puntos de fe, otorgándole puntos de golpe temporales igual a la mitad de tu nivel de sacerdote + tu modificador de Carisma.

#### Consuelo
Cuando restauras puntos de golpe a una criatura con un conjuro de sacerdote de nivel 1 o superior, puedes gastar 1 punto de fe para restaurar puntos de golpe adicionales igual a tu modificador de Carisma a una criatura afectada por el conjuro.

\pagebreakNum

<div style='margin-top:480px'></div>

## Pícaro
*Vas a encontrar una cantidad de organizaciones que codician nuestras habilidades. Aventureros, SI:7... caray, incluso la chusma desorganizada no se opondría a tener un espía o dos dentro de Ventormenta. Pero recuerda esto: Eres tu propio dueño. No dejes que nadie te obligue a hacer algo que no quieras hacer. Además, tenemos todas las cartas... al menos, las tenemos antes de que termine el juego.*
<div style="text-align:Right"> 

*— Jorik Kerridan* &nbsp;</div>

Señalando a sus compañeros para que esperen, una orca se desliza sigilosamente por el pasillo de la mazmorra. Pega la oreja a la puerta y luego saca un juego de herramientas para abrirla en un abrir y cerrar de ojos. Desaparece en las sombras mientras su amigo guerrero avanza para patear la puerta.

Un humano acecha en las sombras de un callejón mientras su cómplice se prepara para su parte de la emboscada. Cuando su objetivo pasa cerca, el cómplice grita, el esclavista se acerca a investigar y la hoja del asesino le corta la garganta antes de que pueda emitir un sonido.

Sofocando una risa, una gnoma se acerca en silencio por detrás de un guardia, robándole el llavero de su cinturón. En un momento, las llaves están en su mano, la puerta de la celda se abre y ella y sus compañeros están listos para escapar.

Los pícaros dependen de la habilidad, el sigilo y las vulnerabilidades de sus enemigos para tomar ventaja en cualquier situación. Tienen un don para encontrar la solución a casi cualquier problema, demostrando una capacidad de recursos y versatilidad que es el pilar de cualquier grupo de aventureros exitoso.

\columnbreak

<div style='margin-top:241px'></div>

### Un Código Simple
Para los pícaros, el único código es su contrato, y su honor se compra con oro. Libres de las restricciones de conciencia, estos mercenarios se basan en tácticas brutales y eficientes. Asesinos letales y maestros del sigilo, se acercan a sus objetivos desde las sombras, perforan un órgano vital y desaparecen antes de que la víctima toque el suelo. Los pícaros pueden sumergir sus armas en toxinas paralizantes que dejan a sus enemigos indefensos. Estos acechadores silenciosos usan armadura de cuero para moverse sin restricciones, asegurándose de dar el primer golpe. Con los venenos y la velocidad del pícaro, el primer golpe suele ser el último paso antes del golpe final.

Los pícaros se valen por sí mismos, buscando enfrentamientos en los que ellos dictan las condiciones. Son las sombras en la noche que permanecen invisibles hasta el momento adecuado para atacar, y despachan a un oponente con trabajo de cuchilla rápido o una toxina mortal introducida con precisión en el torrente sanguíneo. Los pícaros son ladrones oportunistas, bandidos y asesinos, pero hay un arte inigualable en lo que hacen.

### Habilidad y Precisión
Los pícaros se dedican a dominar una gran variedad de habilidades y a perfeccionar sus capacidades de combate, lo que les da una experiencia que pocos pueden igualar. Muchos se enfocan en el sigilo y el engaño, mientras que otros refinan habilidades útiles en mazmorras, como trepar, desactivar trampas y abrir cerraduras.

En combate, los pícaros priorizan el ingenio sobre la fuerza bruta. Un pícaro prefiere hacer un golpe preciso, colocándolo exactamente donde más daño cause al objetivo, en lugar de desgastar al oponente con una ráfaga de ataques. Los pícaros tienen una capacidad casi sobrenatural para evitar el peligro, y algunos aprenden trucos mágicos para complementar sus otras habilidades.

### Creando un Pícaro
Al crear a tu personaje pícaro, considera la relación del personaje con la ley. ¿Tienes un pasado, o presente, criminal? ¿Estás huyendo de la ley o de un maestro de gremio de ladrones enfadado? ¿O dejaste tu gremio en busca de mayores riesgos y recompensas? ¿Es la codicia lo que te impulsa en tus aventuras, o algún otro deseo o ideal?

¿Qué evento desencadenó tu alejamiento de tu vida anterior? ¿Un gran golpe o un robo que salió terriblemente mal te llevó a reevaluar tu carrera? Tal vez tuviste suerte y un robo exitoso te dio las monedas necesarias para escapar de la miseria de tu vida.

<div class='footnote'>PARTE 1 | CLASES</div>
<img src='https://www.gmbinder.com/images/XHxM0Dm.jpg' style='position:absolute; top:0px; right:0px; width:800px; transform:scalex(-1)' />
<img src='https://www.gmbinder.com/images/3e9S91s.png' style='position:absolute; top:100px; right:0px; width:800px; transform:scaley(-1)' />
<img src='https://www.gmbinder.com/images/so5kn8u.png' style='position:absolute; top:40px; right:250px; width:600px; transform:scalex(-1)' />

\pagebreakNum

<div class='classTable wide'>

##### El Pícaro
|Nivel|&nbsp;|Bono de<br>Competencia||Puntos de<br>Energía||Ataque<br>Furtivo|Características|
|:---:|-|:-:|-|:-:|-|:-:|:---------------------------------------|
| 1ro || +2 || —|| 1d6| Pericia, Ataque Furtivo, Misivas Secretas |
| 2do || +2 || 1|| 1d6| Energía, Acción Astuta                   |
| 3ro || +2 || 2|| 2d6| Arquetipo de Pícaro                      |
| 4to || +2 || 2|| 2d6| Mejora de Puntuación de Característica   |
| 5to || +3 || 3|| 3d6| Evasión Sobrenatural                     |
| 6to || +3 || 3|| 3d6| Pericia                                  |
| 7mo || +3 || 4|| 4d6| Evasión                                  |
| 8vo || +3 || 4|| 4d6| Mejora de Puntuación de Característica   |
| 9no || +4 || 5|| 5d6| Rasgo del Arquetipo de Pícaro            |
| 10mo|| +4 || 5|| 5d6| Pie Ligero                               |
| 11vo|| +4 || 6|| 6d6| Talento Confiable                        |
| 12vo|| +4 || 6|| 6d6| Mejora de Puntuación de Característica   |
| 13vo|| +5 || 7|| 7d6| Rasgo del Arquetipo de Pícaro            |
| 14vo|| +5 || 7|| 7d6| Sentido Ciego                            |
| 15vo|| +5 || 8|| 8d6| Anticipación                             |
| 16vo|| +5 || 8|| 8d6| Mejora de Puntuación de Característica   |
| 17vo|| +6 || 9|| 9d6| Rasgo del Arquetipo de Pícaro            |
| 18vo|| +6 || 9|| 9d6| Esquivo                                  |
| 19vo|| +6 ||10||10d6| Mejora de Puntuación de Característica   |
| 20vo|| +6 ||10||10d6| Golpe de Suerte                          |
</div>

&nbsp;&nbsp;&nbsp; ¿El deseo de aventura finalmente te llevó lejos de tu hogar? Quizás te encontraste de repente separado de tu familia o tu mentor, y tuviste que encontrar un nuevo medio de sustento. O tal vez hiciste un nuevo amigo, que te mostró nuevas posibilidades para ganarte la vida y emplear tus talentos particulares.

#### Creación Rápida
Haz que tu caracteristica más alta sea Destreza. Haz que tu siguiente puntuación más alta sea Inteligencia si deseas destacar en Investigación. Elige Carisma si planeas enfocarte en el engaño y la interacción social.

#### Multiclase

***Característica Mínima.*** Debes tener al menos 13 de Destreza para coger un nivel en esta clase, o para tomar un nivel en otra clase si ya eres un pícaro.

***Competencias Adquiridas.*** Armadura ligera, una habilidad de la lista de habilidades de la clase, herramientas de ladrón.

\columnbreak

## Rasgos de Clase

#### Puntos de Golpe
___
- **Dados de Golpe:** 1d8 por nivel de pícaro
- **PG al nivel 1:** 8 + Mod. Constitución
- **PG por nivel:** 1d8 (o 5) + Mod. Constitución por nivel de pícaro

#### Competencias
___
- **Armadura:** Armadura ligera
- **Armas:** Armas simples, ballestas de mano, <br> espadas largas, floretes, espadas cortas
- **Herramientas:** Herramientas de ladrón
- **Tiradas de Salvación:** Destreza, Inteligencia
- **Habilidades:** Elige cuatro de las siguientes habilidades: Acrobacias, Atletismo, Engaño, Perspicacia, Intimidación, Investigación, Percepción, Interpretación, Persuasión, Juego de Manos y Sigilo

#### Equipo
 - *(a)* un estoque o *(b)* una espada corta
 - *(a)* un arco corto y un carcaj con 20 flechas o *(b)* una espada corta
 - *(a)* un paquete de ladrón, *(b)* un paquete de mazmorras o *(c)* un paquete de explorador
 - Armadura de cuero, dos dagas y herramientas de ladrón
<div style='margin-top:-2px;'></div>

<div class='footnote'>PARTE 1 | CLASES</div>

\pagebreakNum

### Pericia
En el 1er nivel, elige dos de tus competencias en habilidades, o una de tus competencias en habilidades y tu competencia con herramientas de ladrón. Tu bono de competencia se duplica para las pruebas de habilidad que realices con cualquiera de las competencias elegidas.

En el 6to nivel, puedes elegir dos competencias más (en habilidades o con herramientas de ladrón) para ganar este beneficio.
<div style='margin-top:-2px;'></div>

### Ataque Furtivo
A partir del 1er nivel, sabes cómo golpear sutilmente y aprovechar la distracción de un enemigo. Una vez por turno, puedes infligir un daño extra de 1d6 a una criatura que golpees con un ataque si tienes ventaja en la tirada de ataque. El ataque debe usar un arma ligera, de precisión o a distancia.

No necesitas tener ventaja en el ataque si otro enemigo del objetivo está a 5 pies de él, ese enemigo no está incapacitado y no tienes desventaja en la tirada de ataque.

La cantidad de daño extra aumenta a medida que ganas niveles en esta clase, como se muestra en la columna de Ataque Furtivo de la tabla del Pícaro.
<div style='margin-top:-2px;'></div>

### Misivas Secretas
Durante tu entrenamiento como pícaro, aprendiste a ocultar mensajes, instrucciones e ideas simples a plena vista. Lo haces mediante la incorporación de jerga sutil y gestos en diálogos aparentemente normales, compartiendo declaraciones con significados ocultos o incluso escribiendo en un código críptico.

Puedes usar 4 horas para compartir un conjunto de estas reglas con otra criatura, permitiéndote entrelazar mensajes y comandos secretos en tus conversaciones y cartas. Las reglas más elaboradas pueden requerir una prueba de Inteligencia, a discreción del DM.
<div style='margin-top:-2px;'></div>

### Energía
En el 2do nivel, aprendes a debilitar aún más a una criatura mediante el uso de energía. Tu nivel de pícaro determina la cantidad de puntos de energía que tienes, como se muestra en la columna de Puntos de Energía de la tabla del Pícaro.

Puedes gastar estos puntos para activar diversas maniobras de energía. Comienzas conociendo tres maniobras: Mutilar, Exponer Armadura y Garrote. Aprendes más maniobras de energía a medida que ganas niveles en esta clase.

Cuando gastas un punto de energía, este no está disponible hasta que termines un descanso breve o largo, al final del cual recuperas toda tu energía gastada.

Tus características de energía requieren que tu objetivo realice una tirada de salvación para resistir sus efectos. La CD de salvación de energía se calcula de la siguiente manera:

<div style="text-align: Center">

**CD de salvación de energía** = <br>8 + Bonus competencia + Mod. Destreza
</div>
<div style='margin-top:-5px;'></div>

#### Mutilar
Inmediatamente después de golpear a una criatura con la acción de Ataque, puedes gastar 1 punto de energía para mutilarla. El objetivo debe superar una tirada de salvación de Fuerza o ser derribado.

\columnbreak

#### Exponer Armadura
Puedes usar tu acción y gastar 1 punto de energía para realizar un ataque especial con arma. Si aciertas, infliges daño normal y expones fallos en su defensa. Cada otra criatura tiene ventaja en la primera tirada de ataque con arma que haga contra el objetivo antes del final de tu siguiente turno.

#### Garrote
Cuando golpeas a una criatura con un ataque cuerpo a cuerpo, puedes gastar 1 punto de energía para garrotearla. El objetivo debe superar una tirada de salvación de Constitución o no podrá hablar hasta el final de tu siguiente turno.

### Acción Astuta
A partir del 2do nivel, tu rápida capacidad de pensar y tu agilidad te permiten moverte y actuar rápidamente. Puedes realizar una acción adicional en cada uno de tus turnos en combate. Esta acción solo se puede usar para realizar las acciones de Correr, Disengage o Esconderse.

### Arquetipo de Pícaro
En el 3er nivel, eliges un área en la que especializarte, que moldea tus habilidades como pícaro: Asesino, Forajido o Sutileza, todos detallados al final de la descripción de la clase. Tu elección de arquetipo te otorga características en el 3er nivel y luego nuevamente en los niveles 9, 13 y 17.

### Mejora de Característica
Cuando alcanzas el nivel 4, y nuevamente en los niveles 8, 12, 16 y 19, puedes aumentar una característica de tu elección en 2, o puedes aumentar dos característica de tu elección en 1. No puedes aumentar una puntuación de característica por encima de 20 usando esta característica.

### Esquiva Sobrenatural
A partir del 5to nivel, cuando un atacante que puedas ver te golpea con un ataque, puedes usar tu reacción para reducir a la mitad el daño del ataque.

### Evasión
En el 7mo nivel, puedes esquivar con agilidad ciertos efectos de área, como el aliento de fuego de un dragón rojo o el conjuro *tormenta de hielo*. Cuando te sometas a un efecto que te permita realizar una tirada de salvación de Destreza para recibir solo la mitad del daño, en su lugar no recibirás daño si tienes éxito en la tirada de salvación, y solo recibirás la mitad del daño si fallas.

### Pie Ligero
A partir del 10mo nivel, tu velocidad aumenta en 10 pies mientras no lleves armadura mediana o pesada.

### Talento Confiable
A partir del 11vo nivel, has perfeccionado tus habilidades elegidas hasta acercarlas a la perfección. Siempre que hagas una prueba de habilidad que te permita añadir tu bono de competencia, puedes considerar una tirada de d20 de 9 o menos como un 10.

<div class='footnote'>PARTE 1 | CLASES</div>

\pagebreakNum

### Sentido Ciego
A partir del 14vo nivel, si eres capaz de oír, eres consciente de la ubicación de cualquier criatura oculta o invisible que esté a 10 pies de ti.

### Anticipación
En el 15vo nivel, siempre estás observando a tus enemigos en busca de oportunidades. En combate, obtienes una segunda reacción que puedes tomar una vez por turno. Puedes usar esta segunda reacción solo para realizar un ataque de oportunidad, y no puedes usarla en el mismo turno en el que usas tu reacción normal.

### Elusivo
A partir del nivel 18, eres tan escurridizo que los atacantes rara vez obtienen ventaja contra ti. Ninguna tirada de ataque tiene ventaja contra ti mientras no estés incapacitado.

### Golpe de Suerte
En el nivel 20, tienes una habilidad asombrosa para tener éxito cuando más lo necesitas. Si tu ataque falla contra un objetivo dentro de tu alcance, puedes convertir el fallo en un impacto. Alternativamente, si fallas una prueba de habilidad, puedes considerar la tirada de d20 como un 20.

Una vez que uses esta característica, no puedes volver a usarla hasta que termines un descanso breve o largo.

\columnbreak

## Arquetipos de Pícaro
Los pícaros tienen muchas características en común, incluida su énfasis en perfeccionar sus habilidades, su enfoque preciso y letal en combate, y sus reflejos cada vez más rápidos. Pero diferentes pícaros dirigen esos talentos en diversas direcciones, representadas por los arquetipos de pícaro.

### Asesino
Te enfocas en el arte sombrío de la muerte, favoreciendo el sigilo y los venenos mortales sobre enfoques directos. Aquellos que se adhieren a esta especialización son diversos: asesinos a sueldo, espías y cazadores de recompensas. El sigilo y el veneno te ayudan a eliminar a tus enemigos con eficiencia letal.

#### Competencia Adicional
Cuando eliges este arquetipo en el nivel 3, obtienes competencia con el equipo de envenenador.

#### Intuición del Asesino
A partir del nivel 3, eres más letal cuando tienes la ventaja inicial sobre tu enemigo. Tienes ventaja en las tiradas de ataque contra cualquier criatura que no haya tomado una acción en el combate aún. Además, tu primer impacto contra una criatura en la primera ronda de cada combate inflige daño adicional con arma igual a tu nivel de Pícaro.

#### Cuchillo Envenenado
Al alcanzar el nivel 9, cuando golpeas a una criatura con un ataque con arma, puedes gastar 1 punto de energía como parte del ataque para envenenar a la criatura. El objetivo debe superar una tirada de salvación de Constitución o quedar envenenado hasta el final de tu siguiente turno.

#### Vendetta
A partir del nivel 13, puedes aprovechar al máximo un momento oportuno. Cuando realizas la acción de Ataque en tu turno y logras un golpe crítico con un ataque con arma, puedes realizar otro ataque con arma como parte de la misma acción de Ataque.

Además, cada vez que una criatura dentro de 5 pies de ti sea golpeada por un ataque crítico realizado por otra criatura que no seas tú, puedes usar tu reacción para realizar un ataque cuerpo a cuerpo contra esa criatura.

#### Sello del Destino
En el nivel 17, te conviertes en un maestro de la muerte instantánea. Cuando golpeas a una criatura con un ataque con arma, puedes forzarla a hacer una tirada de salvación de Constitución contra una CD de 8 + tu modificador de Destreza + tu bonificador de competencia. En caso de fallar la salvación, el daño de tu ataque se duplica.

Una vez que uses esta característica, no puedes volver a usarla hasta que termines un descanso largo.

\pagebreakNum

### Forajido
Los pícaros forajidos son los bribones sin escrúpulos de Azeroth. Doblan las reglas y distorsionan la verdad para conseguir lo que necesitan. Estos forajidos no tienen mucha paciencia para tácticas sigilosas, prefiriendo participar en una pelea de taberna o un duelo espontáneo. Para sobrevivir en un mundo así, los forajidos deben convertirse en maestros espadachines en combate directo y no dudar en usar tácticas sucias.

#### Competencia Adicional
Cuando eliges este arquetipo en el nivel 3, obtienes competencia con pistolas y rifles.

#### Alacridad
Cuando eliges este arquetipo en el nivel 3, tu confianza te impulsa al combate. Puedes darte un bono a tus tiradas de iniciativa igual a tu modificador de Carisma.

Además, aprendes cómo golpear y retirarte sin represalias. Durante tu turno, si haces un ataque cuerpo a cuerpo contra una criatura, esa criatura no puede hacer ataques de oportunidad contra ti durante el resto de tu turno.

#### Punto de Mira
En el nivel 9, inmediatamente después de realizar la acción de Ataque en tu turno, puedes gastar 1 punto de energía para hacer una tirada de ataque a distancia con una pistola cargada como acción adicional, infligiendo daño normal de arma en caso de impacto. Si golpeas a un objetivo dentro de 5 pies de ti, también queda aturdido hasta el final de tu siguiente turno.

Debes estar empuñando una pistola o tener una mano libre para desenfundarla (sin requerir acción) para usar esta maniobra de energía.

#### Trucos del Oficio
A partir del nivel 13, a veces puedes hacer que otra criatura sufra un ataque destinado a ti. Cuando eres el objetivo de un ataque mientras estás a 5 pies de una criatura que no sea el atacante, puedes usar tu reacción para que el ataque apunte a esa criatura en lugar de a ti.

Puedes usar esta característica dos veces. Recuperas todos los usos gastados cuando terminas un descanso breve o largo.

#### Ráfaga de Adrenalina
En el nivel 17, la emoción del combate te revitaliza. Cuando lanzas iniciativa y no tienes puntos de energía restantes, recuperas 2 puntos de energía.

\columnbreak

### Sutileza
Los pícaros de sutileza son maestros de las sombras, y atacan sin ser vistos. Algunos afirman que el arte de la sutileza parece magia sombría, capaces de realizar asaltos devastadores a sus enemigos y retirarse ilesos para volver a atacar sin ser detectados. La mayoría de los pícaros entrenan toda su vida para aprender a caminar en las sombras; los pícaros de sutileza nacieron allí.

#### Conjuración
Cuando eliges este arquetipo en el nivel 3, aprendes a aprovechar la magia de las sombras. Consulta el capítulo 10 del Manual del Jugador para las reglas generales de la magia y el capítulo 6 de este libro para la lista de hechizos de sutileza.

***Trucos.*** Aprendes dos trucos de tu elección de la lista de hechizos de sutileza. Aprendes otro truco de sutileza de tu elección en el nivel 10.

&nbsp;&nbsp;&nbsp; ***Ranuras de Hechizo.*** La tabla de Conjuración de Sutileza muestra cuántas ranuras de hechizo tienes para lanzar tus hechizos de nivel 1 o superior. Para lanzar uno de estos hechizos, debes gastar una ranura de hechizo del nivel del hechizo o superior. Recuperas todas las ranuras de hechizo gastadas cuando terminas un descanso largo.

Por ejemplo, si conoces el hechizo de nivel 1 *orden* y tienes una ranura de hechizo de nivel 1 y una de nivel 2 disponibles, puedes lanzar *orden* usando cualquiera de las dos ranuras.

***Hechizos Conocidos de Nivel 1 y Superior.*** Conoces tres hechizos de sutileza de nivel 1 de tu elección.

La columna de Hechizos Conocidos de la tabla de Conjuración de Sutileza muestra cuándo aprendes más hechizos de sutileza de nivel 1 o superior. Cada uno de estos hechizos debe ser de un nivel para el que tengas ranuras de hechizo. Por ejemplo, cuando alcanzas el nivel 7 en esta clase, puedes aprender un nuevo hechizo de nivel 1 o 2.

Siempre que ganes un nivel en esta clase, puedes reemplazar uno de los hechizos de sutileza que conoces por otro hechizo de tu elección de la lista de hechizos de sutileza. El nuevo hechizo debe ser de un nivel para el que tengas ranuras de hechizo.

***Habilidad para Lanzar Hechizos.*** La Inteligencia es tu habilidad para lanzar tus hechizos de sutileza. Usas tu Inteligencia siempre que un hechizo se refiera a tu habilidad para lanzar hechizos. Además, usas tu modificador de Inteligencia al establecer la CD de salvación para un hechizo de sutileza que lances y al realizar una tirada de ataque con uno.

<div style="text-align: Center">

**CD de salvación del hechizo** = <br>8 + Bonus competencia + Mod. Inteligencia

**Modificador de ataque del hechizo** = <br>Bonus competencia + Mod. Inteligencia
</div>

#### Vista de Penumbra
También a nivel 3, ganas visión en la oscuridad con un alcance de 60 pies. Si ya tienes visión en la oscuridad debido a tu raza, su alcance aumenta en 30 pies.

<div class='footnote'>PARTE 1 | CLASES</div>

\pagebreakNum


#### Paso Sombrío
En el nivel 9, obtienes la capacidad de moverte de una sombra a otra. Cuando te encuentras en penumbra o oscuridad, como acción adicional puedes teletransportarte hasta 60 pies a un espacio vacío que puedas ver y que también esté en penumbra u oscuridad. Luego tienes ventaja en el primer ataque cuerpo a cuerpo que hagas antes del final de tu turno.

#### Capa de Sombras
A partir del nivel 13, puedes usar tu reacción cuando recibes daño de un ataque o hechizo para desaparecer en las sombras, lo que te otorga inmunidad a todo el daño hasta el final de tu próximo turno, incluido el ataque que desencadenó esta reacción.

Puedes usar esta característica dos veces. Recuperas los usos gastados cuando terminas un descanso corto o largo.

#### Duelo Sombrío
En el nivel 17, puedes usar tu acción y gastar 2 puntos de energía para nublar la visión de una criatura dentro de 30 pies de ti. La criatura debe tener éxito en una tirada de salvación de Sabiduría o todo, excepto tú, se volverá fuertemente oscurecido para ella durante 1 minuto.

Al final de cada uno de sus turnos, el objetivo puede realizar otra tirada de salvación de Sabiduría, terminando el duelo sombrío con un éxito.

<div class='classTable' style='margin-top:50px;'>

##### Conjuración de Sutileza
|Nivel de<br>Pícaro|Trucos<br>Conocidos|Hechizos<br>Conocidos|1º|&nbsp;|2º|&nbsp;|3º|&nbsp;|4º|
|:---:|:-:|:--:|:--:|-|:--:|-|:--:|-|:--:|
| 3  | 3  |  3 |2||—||—||—|
| 4  | 3  |  4 |3||—||—||—|
| 5  | 3  |  4 |3||—||—||—|
| 6  | 3  |  4 |3||—||—||—|
| 7  | 3  |  5 |4||2||—||—|
| 8  | 3  |  6 |4||2||—||—|
| 9  | 3  |  6 |4||2||—||—|
| 10 | 4  |  7 |4||3||—||—|
| 11 | 4  |  8 |4||3||—||—|
| 12 | 4  |  8 |4||3||—||—|
| 13 | 4  |  9 |4||3||2||—|
| 14 | 4  | 10 |4||3||2||—|
| 15 | 4  | 10 |4||3||2||—|
| 16 | 4  | 11 |4||3||3||—|
| 17 | 4  | 11 |4||3||3||—|
| 18 | 4  | 11 |4||3||3||—|
| 19 | 4  | 12 |4||3||3||1|
| 20 | 4  | 13 |4||3||3||1|
</div>

\columnbreak

### Conjuros de Sutileza

<div style='column-count:2'>

##### Trucos (Nivel 0)
Protección con Cuchilla  
Hoja Retumbante ^SCAG^  
Amigos  
Ráfaga ^EE^  
Mano Mágica  
Mensaje  
Ilusión Menor  
Prestidigitación  
Explosión de Espadas ^SCAG^  
Conocer la Intención

##### Nivel 2
Alterar el Yo  
Ceguera/Sordera  
Desenfoque  
Oscuridad  
Visión Nocturna  
Invisibilidad  
Arma Mágica  
Imagen Espejo  
Pasar Sin Rastro  
Sugestión

##### Nivel 4
Compulsión  
Confusión  
Libertad de Movimiento  
Invisibilidad Mayor  
Terreno Alucinatorio

\columnbreak

##### Nivel 1
Maldición  
Orden  
Duelo Obligado  
Disfrazarse  
Susurros Disonantes  
Retirada Expeditiva  
Nube de Niebla  
Salto  
Pies Ligeros  
Imagen Silenciosa

##### Nivel 3
Enemigos Abundan ^XGE^  
Aceleración  
Patrón Hipnótico  
Imagen Mayor  
No Detección  
Envío  
Lentitud
</div>

<div class='footnote'>PARTE 1 | CLASES</div>

\pagebreakNum

<div style='margin-top:505px;'></div>

## Chamán
*Los lobos no están domesticados, al menos no como tú podrías entender la palabra. Han venido a ser nuestros amigos porque los invité. Es parte de ser un chamán. Tenemos un vínculo con las cosas del mundo natural y nos esforzamos por trabajar en armonía con ellas. Los brujos los llamarían hechizos, pero los chamanes simplemente los llamamos llamadas. Pedimos, y los poderes con los que trabajamos responden. O no, según lo deseen. Puedo llamar a las nieves, al viento y al rayo. Los árboles pueden inclinarse ante mí cuando lo pido. Los ríos pueden fluir hacia donde yo pida.*  
<div style="text-align:Right"> 

*— Drek'Thar del clan Lobo Gélido*  </div>

Un orco con placas sueltas unidas por cadenas se alza sobre una solitaria cumbre. Los vientos arremolinan a su alrededor, haciendo tintinear las cadenas, antes de liberar un rayo brillante hacia sus enemigos.

Un enano de cabello gris camina por el campo de batalla, vaciando una botella de agua sobre la tierra mientras avanza. Luego, la levanta y agita suavemente sobre un aliado herido, aliviando sus graves heridas.

Los chamanes son mediadores entre los elementos, actuando como guías espirituales de sus comunidades. Pueden comunicarse con los espíritus ancestrales y canalizar los poderes elementales en sus conjuros, ya sea para sanar y fortalecer a sus aliados o para lanzar ataques devastadores. Pueden imbuir sus armas con poder elemental, castigar a sus enemigos con tormentas y fuego, y convocar elementales para que los ayuden.

\columnbreak

<div style='margin-top:340px;'></div>

### Heraldo de los Elementos
El vínculo de un chamán con la magia es único. Mientras que un mago estudia la magia y un brujo intenta someterla, un chamán llama a los elementos. Se comunican con fuerzas que no son necesariamente benévolas; a veces estas fuerzas responden y a veces no. Los elementos son caóticos, enfrentados entre sí con una furia primitiva. El proposito del chamán es traer equilibrio a ese caos.

Estos maestros de los elementos pueden invocar fuerzas elementales, desatando lava y rayos contra sus enemigos. Los elementos pueden crear, destruir, apoyar y obstaculizar. Un chamán experimentado equilibra estas fuerzas en un conjunto de habilidades diversas, haciéndolo un aventurero versátil y un miembro valioso de cualquier grupo.

### Respetado y Temido
DDesde los primeros días de la vida mortal en Azeroth y Draenor, los elementos han sido temidos y venerados. Los místicos han buscado comunicarse con ellos para aprovechar el poder puro de la tierra, el aire, el fuego y el agua. Con el tiempo, estos guías espirituales comprendieron la gravedad y complejidad de los poderes que manejan. Los elementos no son completamente benévolos, sino fuerzas en constante conflicto, con los señores elementales luchando por el control. El llamado del chamán es ser un conducto de estas energías volátiles, utilizándolas tanto para sanar como para dañar.

### Creando un Chamán
Al crear un chamán, considera cómo tu vínculo con los elementos ha afectado tu personalidad y tu visión del mundo. Aunque los chamanes resuenan con los cuatro elementos primarios, algunos tienden a mostrar aspectos de uno por encima del resto.

Los chamanes que se inclinan hacia el fuego pueden ser impacientes, temperamentales o llenos de energía en todo lo que hacen. Los que se inclinan hacia el agua son adaptables, caóticos y tienden a "fluir" con la situación.

Aquellos que favorecen la tierra suelen ser legales, firmes y tercos. Y los que favorecen el aire suelen ser distantes, desapegados y los más neutrales en sus arbitrajes.

<div class='footnote'>PARTE 1 | CLASES</div>
<img src='https://www.gmbinder.com/images/08Vyjyt.jpg' style='position:absolute; top:0px; right:-200px; width:1000px' />
<img src='https://www.gmbinder.com/images/bNHsRrG.png' style='position:absolute; top:-40px; right:0px; width:900px; transform:scaley(-1)' />
<img src='https://www.gmbinder.com/images/o5JVP3V.png' style='position:absolute; top:0px; right:400px; width:550px; transform:scalex(-1)' />

\pagebreakNum

<div class='classTable wide'>

##### El Chamán
|Nivel|Bonif.<br>Compet.|Características|Conjuros<br>Conocidos|&nbsp;|Hechizos<br>Conocidos|&nbsp;|1.º|&nbsp;|2.º|&nbsp;|3.º|&nbsp;|4.º|&nbsp;|5.º|&nbsp;| 6.º|&nbsp;|7.º|&nbsp;|8.º|&nbsp;|9.º <div style="position: absolute; top:100px; right:95px; width:200px; height:25px">—Ranuras de Conjuros por Nivel de Hechizo—</div>|
|:---:|:--:|:----------------------------|:-:|-|:-:|-|:-:|-|:-:|-|:-:|-|:-:|-|:-:|-|:-:|-|:-:|-|:-:|-|:-:|
| 1.º | +2 | Kalimag, Lanzamiento de conjuros                    |2|| 4||2||—||—||—||—||—||—||—||—|
| 2.º | +2 | Totemista (2/descanso), <br> Afinidad Elemental     |2|| 5||3||—||—||—||—||—||—||—||—|
| 3.º | +2 | Vínculo Chamánico                                  |2|| 6||4||2||—||—||—||—||—||—||—|
| 4.º | +2 | Mejora de puntuación de característica              |3|| 7||4||3||—||—||—||—||—||—||—|
| 5.º | +3 | Bestia Espiritual                                  |3|| 8||4||3||2||—||—||—||—||—||—|
| 6.º | +3 | Característica de Vínculo Chamánico                 |3|| 9||4||3||3||—||—||—||—||—||—|
| 7.º | +3 | —                                                  |3||10||4||3||3||1||—||—||—||—||—|
| 8.º | +3 | Mejora de puntuación de característica              |3||11||4||3||3||2||—||—||—||—||—|
| 9.º | +4 | Mejora de Afinidad Elemental                       |3||12||4||3||3||3||1||—||—||—||—|
| 10.º| +4 | Proyección Totémica, <br> Totemista (3/descanso)   |4||14||4||3||3||3||2||—||—||—||—|
| 11.º| +4 | —                                                  |4||15||4||3||3||3||2||1||—||—||—|
| 12.º| +4 | Mejora de puntuación de característica              |4||15||4||3||3||3||2||1||—||—||—|
| 13.º| +5 | Visión Lejana                                      |4||16||4||3||3||3||2||1||1||—||—|
| 14.º| +5 | Característica de Vínculo Chamánico                 |4||18||4||3||3||3||2||1||1||—||—|
| 15.º| +5 | —                                                  |4||19||4||3||3||3||2||1||1||1||—|
| 16.º| +5 | Mejora de puntuación de característica              |4||19||4||3||3||3||2||1||1||1||—|
| 17.º| +6 | —                                                  |4||20||4||3||3||3||2||1||1||1||1|
| 18.º| +6 | Totemista (4/descanso)                             |4||22||4||3||3||3||3||1||1||1||1|
| 19.º| +6 | Mejora de puntuación de característica              |4||22||4||3||3||3||3||2||1||1||1|
| 20.º| +6 | Característica de Vínculo Chamánico                 |4||22||4||3||3||3||3||2||2||1||1|
</div>

&nbsp;&nbsp;&nbsp; Reflexiona sobre tu vínculo con tus tótems y cómo representan los planos elementales de los que obtienes tu poder. ¿Son simplemente herramientas para canalizar energía plana, o son sagrados y dignos de reverencia? 

¿Actúan como representaciones de un elemento favorito, o los utilizas para mantener ese elemento bajo control? La percepción de un chamán sobre su conexión con los planos elementales a menudo se refleja en los tótems que invoca.

#### Multiclase

***Caracteristica Mínima.*** Debes tener al menos un 13 de Sabiduría para coger un nivel en esta clase, o para coger un nivel en otra clase si ya eres chamán.

***Competencias Adquiridas.*** Armadura ligera, armadura media, escudos y armas simples.

***Ranuras de Conjuros.*** Suma tus niveles de la clase de chamán (o la mitad de tus niveles si eliges la subclase de Mejora) a los niveles apropiados de otras clases para determinar tus ranuras de conjuros disponibles.

#### Creación Rápida
Haz de Sabiduría tu caracteristica principal, seguida de Constitución. Si planeas participar regularmente en combate cuerpo a cuerpo, haz que tu segunda puntuación más alta sea Fuerza o Destreza.

## Rasgos de Clase

#### Puntos de Golpe
___
- **Dado de Golpe:** 1d8 por nivel de chamán
- **PG al nivel 1:** 8 + Mod. Constitución
- **PG por nivel:** 1d8 (o 5) + Mod. Constitución por cada nivel de chamán

#### Competencias
___
- **Armadura:** Armadura ligera, armadura media, escudos
- **Armas:** Armas simples
- **Herramientas:** Kit de herboristería
- **Tiradas de Salvación:** Fuerza, Sabiduría
- **Habilidades:** Elige dos entre Trato con animales, Arcanos, Historia, Perspicacia, Medicina, Naturaleza, Percepción y Supervivencia
 
#### Equipo
 - *(a)* armadura de pieles o *(b)* armadura de cuero
 - *(a)* una maza y un escudo o *(b)* dos armas simples
 - *(a)* un paquete de aventurero o *(b)* un paquete de explorador
 - un enfoque druídico

<div class='footnote'>PARTE 1 | CLASES</div>

\pagebreakNum


<div style='margin-top:-3px;'></div>

### Kalimag
Conoces Kalimag, el idioma de los elementales. Puedes hablar el idioma y usarlo para dejar mensajes en rocas y charcas de agua que solo tú y otros chamanes pueden notar. Los mensajes se transmiten como si fuera un conjuro de *mensaje*, con las limitaciones de dicho conjuro.
<div style='margin-top:-3px;'></div>

### Lanzamiento de Conjuros
Al conectarte con los elementos, puedes manifestar su poder mediante conjuros. Consulta el capítulo 10 del Manual del Jugador para las reglas generales sobre lanzamiento de conjuros y el capítulo 6 de este libro para la lista de conjuros del chamán.

#### Conjuros Truco
Conoces dos conjuros truco de tu elección de la lista de conjuros del chamán. Aprendes más conjuros truco adicionales a niveles superiores, como se muestra en la columna de Conjuros Conocidos de la tabla del Chamán.

#### Ranuras de Conjuros
La tabla del Chamán muestra cuántas ranuras de conjuros tienes para lanzar tus conjuros de nivel 1 o superior. Para lanzar uno de estos conjuros, debes gastar una ranura de conjuros del nivel correspondiente o superior. Recuperas todas las ranuras de conjuros gastadas al finalizar un descanso prolongado.

#### Conjuros Conocidos de Nivel 1 o Superior
Conoces cuatro conjuros de nivel 1 de tu elección de la lista de conjuros del chamán.

La columna de Conjuros Conocidos de la tabla del Chamán muestra cuándo aprendes más conjuros de tu elección. Cada uno de estos conjuros debe ser de un nivel para el que tengas ranuras de conjuros. Por ejemplo, cuando alcanzas el nivel 3 en esta clase, aprendes un nuevo conjuro de nivel 1 o 2.

Además, cuando subes de nivel en esta clase, puedes elegir uno de los conjuros de chamán que conoces y reemplazarlo por otro conjuro de la lista del chamán, que también debe ser de un nivel para el que tengas ranuras de conjuros.

#### Habilidad para Lanzar Conjuros
La Sabiduría es tu habilidad para lanzar conjuros de chamán, ya que tu poder proviene de los elementos y los espíritus. Usas tu Sabiduría siempre que un conjuro de chamán haga referencia a tu habilidad para lanzar conjuros. Además, utilizas tu modificador de Sabiduría para establecer la CD de salvación de los conjuros de chamán que lanzas y al hacer una tirada de ataque con uno.

<div style="text-align: Center">

**CD de salvación de conjuro** = <br>8 + Bonus competencia + Mod. Sabiduría

**Bonificador de ataque de conjuro** = <br>Bonus competencia + Mod. Sabiduría
</div>

#### Lanzamiento Ritual
Puedes lanzar un conjuro de chamán que conozcas como ritual si ese conjuro tiene la etiqueta de ritual.

#### Enfoque para Lanzar Conjuros
Puedes usar un enfoque druídico como enfoque para lanzar tus conjuros de chamán.

\columnbreak

### Totemista
A partir del nivel 2, puedes usar tu acción adicional para canalizar fuerzas elementales en un tótem Pequeño en un espacio vacío sobre una superficie horizontal a 15 pies de ti.

El tótem es un objeto mágico que ocupa su espacio. Tiene una CA de 15 y un número de puntos de golpe igual al doble de tu nivel de chamán. Es inmune al daño por veneno, daño psíquico y a todas las condiciones. Si se ve obligado a realizar un chequeo de característica o una tirada de salvación, todos sus valores de característica son 10 (+0). El tótem desaparece si se reduce a 0 puntos de golpe o tras 1 minuto. Puedes disiparlo antes como una acción adicional.

Puedes usar tu reacción para hacer que el tótem se active si estás a 60 pies de él y elijes uno de sus poderes para que surta efecto. Tu tótem comienza con dos de estos poderes: Resistencia Elemental y un poder determinado por tu Afinidad Elemental. Tu tótem gana un poder adicional al nivel 3, determinado por tu vínculo chamánico.

Puedes usar tu característica de Totemista dos veces entre descansos. Recuperas todos los usos gastados al finalizar un descanso breve o prolongado. Puedes invocar un tótem adicional entre descansos al alcanzar el nivel 10, y nuevamente al nivel 18.
<div style='margin-top:-6px;'></div>

***Poder Totémico: Resistencia Elemental.*** Puedes activar el tótem cuando una criatura a 15 pies de él reciba daño de ácido, frío, fuego, rayo o trueno, otorgándoles resistencia a ese tipo de daño hasta el final de su siguiente turno.

\pagebreakNum

### Afinidad Elemental
A partir del nivel 2, te sintonizas con una fuerza del plano elemental. Elige una de las siguientes opciones. No puedes tomar una opción de Afinidad Elemental más de una vez, incluso si más adelante tienes la oportunidad de elegir nuevamente.

#### Sintonización de Aire
Tu velocidad de movimiento aumenta en 5 pies y puedes añadir tu bonificador de competencia a tu iniciativa.

A nivel 9, ganas resistencia al daño por rayos.
<div style='margin-top:-6px;'></div>

***Poder Totemico: Gracia del Aire.*** Puedes activar el tótem cuando una criatura a 15 pies de él realice un chequeo o tirada de salvación de Destreza, otorgándole ventaja en su tirada.

#### Sintonización de Tierra
Ganas competencia en tiradas de salvación de Constitución.

A nivel 9, obtienes resistencia al daño por ácido.
<div style='margin-top:-6px;'></div>

***Poder Totemico: Fuerza de la Tierra.*** Puedes activar el tótem cuando una criatura a 15 pies de él realice un chequeo o tirada de salvación de Fuerza, otorgándole ventaja en su tirada.

#### Sintonización de Fuego
Cuando golpeas a una criatura con una tirada de ataque que no puede golpear a más de una criatura, puedes infligir daño adicional por fuego igual a tu bonificador de competencia. Puedes usar esta afinidad una vez por turno.

A nivel 9, ganas resistencia al daño por fuego.
<div style='margin-top:-6px;'></div>

***Poder Totemico: Lengua de Fuego.*** Puedes activar el tótem cuando una criatura a 15 pies de él realice un chequeo o tirada de salvación de Carisma, otorgándole ventaja en su tirada.

#### Sintonización de Agua
Conoces un número adicional de conjuros de chamán de nivel 1 o superior igual a tu bonificador de competencia.

A nivel 9, obtienes resistencia al daño por frío.
<div style='margin-top:-6px;'></div>

***Poder Totemico: Corriente Purificadora.*** Puedes activar el tótem cuando una criatura a 15 pies de él realice un chequeo o tirada de salvación de Sabiduría, otorgándole ventaja en su tirada.

### Vínculo Chamánico
A nivel 3, eliges un vínculo chamánico que define tu enfoque hacia las fuerzas de los elementos. Elige entre Elemental, Mejora o Restauración, cada uno de los cuales se detalla al final de la descripción de la clase. Tu elección te otorga características al nivel 3 y nuevamente al 6.º, 14.º y 20.º nivel.

### Mejora de Puntuación de Característica
Cuando alcanzas el nivel 4, y nuevamente en los niveles 8, 12, 16 y 19, puedes aumentar una puntuación de característica de tu elección en 2, o puedes aumentar dos puntuaciones de característica de tu elección en 1. Como es habitual, no puedes aumentar una puntuación de característica por encima de 20 con esta característica.

\columnbreak

### Bestia Espiritual
A nivel 5, obtienes el favor de una bestia espiritual y eres capaz de asumir su apariencia espectral. Elige una bestia Mediana o Pequeña que no tenga velocidad de vuelo o nado para representar tu espíritu.

Puedes usar tu acción para asumir la apariencia ilusoria de tu bestia espiritual. Esta apariencia no afecta a tus estadísticas de juego, excepto que cambia tu velocidad de movimiento a 50 pies.

Permaneces transformado hasta que lances un conjuro, realices un ataque o uses tu acción adicional para regresar a tu forma original.

### Proyección Totémica
A nivel 10, puedes canalizar fuerzas elementales en un tótem a mayores distancias, aumentando la distancia a la que puedes invocar tu tótem a 30 pies, y mientras estés a 60 pies de tu tótem, puedes usar una acción adicional para mover el tótem a un espacio vacío dentro del alcance, como si lo hubieras invocado de nuevo.

Además, puedes manifestar conjuros simples pero efectivos a través de tu tótem. Puedes usar tu acción para lanzar un conjuro truco de chamán con un alcance de 5 pies o más a través del tótem, como si estuvieras en el espacio del tótem.

### Visión Lejana
A partir del nivel 13, puedes afinar tu vista y enfocarla en una criatura que hayas visto antes. Al realizar un ritual de 10 minutos, puedes intentar lanzar el conjuro *adivinación* sin proporcionar componentes materiales. Lanza un dado de porcentaje; si el resultado es menor que tu nivel de Chamán, lanzas el conjuro *adivinación*.

Una vez que uses esta característica, no podrás volver a usarla hasta que termines un descanso prolongado.

## Vínculo Chamánico
Los chamanes se esfuerzan por profundizar su comprensión y conexión con los elementos, a menudo formando un vínculo de por vida. Algunos prefieren un enfoque más brutal, dominando los poderes de fuego y tierra para el combate físico, o las fuerzas de fuego y aire para luchar a distancia. Otros, en cambio, prefieren un enfoque sutil de paz y meditación, doblando el agua y el aire a su voluntad. Te sintonizas con uno de estos grupos.

<div class='footnote'>PARTE 1 | CLASES</div>

<img src='https://www.gmbinder.com/images/GJ0XjPx.png' style='position:absolute; top:800px; right:90px; width:250px' />

\pagebreakNum

### Elemental
Mediante un estudio cuidadoso y dedicación, los chamanes elementales pueden canalizar la energía volátil del Plano Elemental en oleadas mágicas destructivas. Relámpagos fluyen a través de su cuerpo, como si fueran tormentas, y explosiones de fuego, como si emanaran de la tierra fundida. Enfrentarse a un chamán elemental es desafiar a las propias fuerzas de la naturaleza.

#### Poder Totémico
Cuando eliges este vínculo a nivel 3, obtienes el siguiente Poder Totémico.
<div style='margin-top:-6px;'></div>

***Poder Totemico: Mente Tranquila.*** Puedes activar el tótem cuando una criatura a 15 pies de él se vea obligada a realizar una tirada de salvación de Constitución para mantener la concentración, otorgándole ventaja en la tirada.

#### Furia Elemental
A partir del nivel 3, cuando lances un conjuro que inflija daño de ácido, frío, fuego, rayo o trueno, puedes sustituir ese tipo de daño por otro tipo de la lista (solo puedes cambiar un tipo de daño por lanzamiento de conjuro).

#### Conjuros de Vínculo
Tu sintonía con el Plano Elemental te otorga la capacidad de lanzar ciertos conjuros. Aprendes conjuros adicionales relacionados con tu Afinidad Elemental al alcanzar ciertos niveles en esta clase, como se muestra en tu tabla de conjuros de elementos. Estos conjuros cuentan como conjuros de chamán para ti, pero no cuentan para el número de conjuros de chamán que conoces. No puedes reemplazar estos conjuros al ganar un nivel en esta clase.

#### Eco de los Elementos
A nivel 6, cuando lances un conjuro de chamán que cause daño, puedes volver a tirar un número de dados de daño hasta tu modificador de Sabiduría y usar cualquiera de los resultados.

Puedes usar esta característica un número de veces igual a tu modificador de Sabiduría. Recuperas los usos gastados al finalizar un descanso prolongado.

#### Santuario Primordial
Al alcanzar el nivel 14, las criaturas elementales del mundo sienten tu conexión con el Plano Elemental y dudan en atacarte. Cuando una criatura elemental te ataque, debe hacer una tirada de salvación de Sabiduría contra la CD de salvación de tus conjuros de chamán. Si falla, debe elegir otro objetivo, o el ataque falla automáticamente. Si tiene éxito, es inmune a este efecto durante 24 horas.

La criatura es consciente de este efecto antes de realizar su ataque contra ti.

\columnbreak

#### Ascendencia
A nivel 20, puedes asumir la forma de un ascendente elemental. Usando tu acción, sufres una transformación. Durante 1 minuto, obtienes los siguientes beneficios:

- Obtienes inmunidad al daño del tipo de tu afinidad elemental.
- Cuando vuelvas a tirar un dado con tu característica Eco de los Elementos, sumas ambos resultados al daño del conjuro.
- Puedes usar tu reacción al ser golpeado por un ataque cuerpo a cuerpo para hacer que el atacante reciba daño del tipo de tu afinidad elemental igual a tu nivel de chamán.

Una vez que uses esta característica, no podrás usarla de nuevo hasta un descanso largo.

##### Aire
|&nbsp; Nivel de Chamán | Conjuros de Vínculo |
|:---------:|:-------------------------|
|&nbsp; 3 | *demonio de polvo ^XGE^, viento protector ^XGE^* |
|&nbsp; 5 | *invocar relámpagos, muro de viento* |
|&nbsp; 7 | *libertad de movimiento, esfera de tormenta ^XGE^* |
|&nbsp; 9 | *conjurar elemental (aire), controlar vientos ^XGE^* |
<div style='margin-top:-5px;'></div>

##### Tierra
|&nbsp; Nivel de Chamán | Conjuros de Vínculo |
|:---------:|:-------------------------|
|&nbsp; 3 | *mano de tierra ^XGE^, destrozar* |
|&nbsp; 5 | *✦ pico de tierra, tierra en erupción ^XGE^* |
|&nbsp; 7 | *terreno ilusorio, piel pétrea* |
|&nbsp; 9 | *conjurar elemental (tierra), muro de piedra* |
<div style='margin-top:-5px;'></div>

##### Fuego
|&nbsp; Nivel de Chamán | Conjuros de Vínculo |
|:---------:|:-------------------------|
|&nbsp; 3 | *metal ardiente, ✦ ráfaga de lava* |
|&nbsp; 5 | *luz solar, meteoros menudos ^XGE^* |
|&nbsp; 7 | *escudo de fuego, muro de fuego* |
|&nbsp; 9 | *conjurar elemental (fuego), golpe de llamas* |
<div style='margin-top:-5px;'></div>

##### Agua
|&nbsp; Nivel de Chamán | Conjuros de Vínculo |
|:---------:|:-------------------------|
|&nbsp; 3.º | *auxilio, restauración menor* |
|&nbsp; 5.º | *✦ cadena de sanación, muro de agua ^XGE^* |
|&nbsp; 7.º | *controlar agua, protección contra la muerte* |
|&nbsp; 9.º | *conjurar elemental (agua), vorágine ^XGE^* |
<div style='margin-top:-5px;'></div>

*✦ Los nuevos conjuros se pueden encontrar en el capítulo 6 de este libro*

\pagebreakNum

### Mejora
La comunión intensa con el fuego, la tierra, el aire y el agua no es exclusiva del chamán elemental. En muchos aspectos, los chamanes de mejora también se vinculan con la naturaleza y aprovechan su poder en el campo de batalla. Estos chamanes prefieren potenciar sus ataques físicos con energías elementales y enfrentarse a sus adversarios de cerca.

#### Poder Totémico
Cuando eliges este vínculo a nivel 3, obtienes el siguiente Poder Totémico.
<div style='margin-top:-6px;'></div>

***Poder Totemico: Furia del Viento.*** Puedes activar este tótem cuando una criatura a 15 pies de él falle un ataque con un arma cuerpo a cuerpo; esa criatura puede intentar el mismo ataque con el arma de inmediato contra el objetivo.

#### Competencia Adicional
A nivel 3, obtienes competencia con armas marciales y puedes usar un arma simple o marcial como enfoque para lanzar tus conjuros de chamán.

#### Llamado Marcial
A partir del nivel 3, consulta la tabla de Lanzamiento de Conjuros de Mejora para determinar tus conjuros truco, conjuros conocidos y ranuras de conjuros cada vez que subas de nivel en esta clase. También cuentas como *medio lanzador* para determinar las ranuras de conjuros disponibles cuando multiclaseas con otras clases.

<div class='classTable' style='margin-top:40px;'>

##### Lanzamiento de Conjuros de Mejora
|Nivel de <br> Chamán|Conjuros <br> Conocidos|Hechizos <br> Conocidos|&nbsp;|1.º|&nbsp;|2.º|&nbsp;|3.º|&nbsp;|4.º|&nbsp;|5.º|
|:---:|:-:|:--:|-|:--:|-|:--:|-|:--:|-|:--:|-|:--:|
| 3.º | 2 | 5||3||—||—||—||—|
| 4.º | 2 | 5||3||—||—||—||—|
| 5.º | 2 | 5||4||2||—||—||—|
| 6.º | 2 | 6||4||2||—||—||—|
| 7.º | 2 | 6||4||3||—||—||—|
| 8.º | 2 | 6||4||3||—||—||—|
| 9.º | 2 | 7||4||3||2||—||—|
| 10.º| 3 | 7||4||3||2||—||—|
| 11.º| 3 | 7||4||3||3||—||—|
| 12.º| 3 | 8||4||3||3||—||—|
| 13.º| 3 | 8||4||3||3||1||—|
| 14.º| 3 | 8||4||3||3||1||—|
| 15.º| 3 | 9||4||3||3||2||—|
| 16.º| 3 | 9||4||3||3||2||—|
| 17.º| 3 |10||4||3||3||3||1|
| 18.º| 3 |10||4||3||3||3||1|
| 19.º| 3 |11||4||3||3||3||2|
| 20.º| 3 |11||4||3||3||3||2|
</div>

<div class='footnote'>PARTE 1 | CLASES</div>

<img src='https://www.gmbinder.com/images/QVJZTHd.jpg' style='position:absolute; top:0px; right:-200px; width:880px' />
<img src='https://www.gmbinder.com/images/E8GrMME.png' style='position:absolute; top:0px; right:0px; width:900px' />

\pagebreakNum

#### Torbellino
También a nivel 3, puedes aprovechar las fuerzas del torbellino y canalizarlas en tus armas.

***Puntos de Torbellino.*** Tienes un número de puntos de torbellino igual a la mitad de tu nivel de chamán (redondeado hacia arriba). Puedes gastar estos puntos para potenciar diversos ataques con armas. Cuando gastas un punto de torbellino, no está disponible hasta que completes un descanso breve o largo, al final del cual recuperas todos los puntos de torbellino gastados.

***Ataques con Armas.*** Conoces dos ataques con armas de tu elección, que se detallan a continuación en "Ataques con Armas". Los ataques con armas mejoran un ataque de alguna manera. Solo puedes usar un ataque por cada ataque, salvo que se indique lo contrario.

Aprendes un ataque con armas adicional de tu elección a nivel 7, 11 y 15. Cada vez que aprendas un nuevo ataque, puedes reemplazar uno que conozcas por otro diferente.

***Tiradas de Salvación.*** Algunos de tus ataques requieren que tu objetivo haga una tirada de salvación para resistir el efecto. La CD de la tirada de salvación es igual a tu CD de salvación de conjuros.

#### Ataque Adicional
A partir del nivel 6, puedes atacar dos veces, en lugar de una, cuando realices la acción de ataque en tu turno.

#### Vigor Chamánico
A partir del nivel 9, puedes lanzar *sed de sangre y heroísmo* sin gastar una ranura de conjuro. Una vez que lo uses de esta manera, no podrás volver a hacerlo hasta que termines un descanso prolongado.

#### Fusión Elemental
Al alcanzar el nivel 14, puedes elegir una segunda opción de la característica de clase Afinidad Elemental.

#### Elementos de Mejora
A nivel 20, puedes aprovechar las energías de tus elementos sintonizados, obteniendo los siguientes beneficios según tus Afinidades Elementales.

***Aire.*** Tu puntuación de Destreza aumenta en 2 y tu máximo para esta puntuación ahora es 22.

***Tierra.*** Tu puntuación de Fuerza aumenta en 2 y tu máximo para esta puntuación ahora es 22.

***Fuego.*** Tu puntuación de Carisma aumenta en 2 y tu máximo para esta puntuación ahora es 22.

***Agua.*** Tu puntuación de Sabiduría aumenta en 2 y tu máximo para esta puntuación ahora es 22.

\columnbreak

#### Ataques con Armas
Los ataques con armas se presentan en orden alfabético.

***Golpe de Roca.*** Cuando golpeas a una criatura con un ataque con arma, puedes gastar 1 punto de torbellino para obligarla a realizar una tirada de salvación de Fuerza. Si falla, es empujada 15 pies directamente lejos de ti.

***Golpe Impactante (Requiere nivel 7).*** Cuando golpeas a una criatura con un ataque con arma, puedes gastar 3 puntos de torbellino para intentar un golpe impactante. La criatura debe superar una tirada de salvación de Constitución o quedar incapacitada hasta el comienzo de tu próximo turno.

***Latigo Elemental.*** Cuando golpeas a una criatura con un ataque con arma, puedes gastar 1 punto de torbellino para azotar a otra criatura diferente de tu elección a 15 pies de ella con los elementos. La segunda criatura debe superar una tirada de salvación de Destreza o recibir 1d10 del tipo de daño de tu Afinidad Elemental. Eliges el tipo de daño de tu Afinidad Elemental cuando activas este ataque.

***Golpe Elemental.*** Cuando realices la acción de ataque, puedes gastar 1 punto de torbellino para envolver tus ataques en el elemento de tu Afinidad Elemental hasta el final de tu turno. Cada ataque inflige 1d4 de daño adicional del tipo de tu afinidad elemental si golpea. Eliges el tipo de daño de tu Afinidad Elemental cuando activas este ataque.

Puedes usar Golpe Elemental en combinación con otro ataque al realizar un ataque.

***Marca de Hielo.*** Cuando golpeas a una criatura con un ataque con arma, puedes gastar 1 punto de torbellino para intentar una marca helada. El objetivo debe superar una tirada de salvación de Constitución o tendrá desventaja en ataques con armas hasta el final de su próximo turno.

***Golpe de Torbellino.*** Cuando realices la acción de ataque, puedes gastar 1 punto de torbellino para que todos tus ataques con armas cuenten como mágicos hasta el final de tu turno.

Puedes usar Golpe de Torbellino en combinación con otro ataque al realizar un ataque.

***Mordida de Roca.*** Cuando golpeas a una criatura con un ataque con arma, puedes gastar 1 punto de torbellino para intentar un golpe que derriba. El objetivo debe superar una tirada de salvación de Fuerza o caerá derribado.

***Golpe de Tormenta.*** Cuando golpeas a una criatura con un ataque con arma, puedes gastar 1 punto de torbellino para descargar un rayo sobre ella. La criatura debe superar una tirada de salvación de Constitución o no podrá tomar reacciones hasta el comienzo de tu próximo turno.

\pagebreakNum

### Restauración
Algunos chamanes encuentran serenidad en las propiedades restaurativas del agua. No buscan la Luz ni se vuelven hacia lo divino, pero sienten una profunda conexión espiritual con la fuente de la vida mortal. Tan fuerte es su vínculo con el agua que el chamán puede extraer su poder para restaurar la vida y curar aflicciones, como una ola que arrasa una playa arenosa. Mantienen un equilibrio con los demás elementos, buscando armonía.

#### Poder Totémico
Cuando eliges este vínculo a nivel 3, obtienes el siguiente Poder Totémico.
<div style='margin-top:-6px;'></div>

***Poder Totémico: Marea Viva.*** Puedes activar este tótem cuando una criatura a 15 pies de él lanza un conjuro o usa una habilidad que restaura puntos de golpe, causando que el tótem irradie una marea viva hacia una criatura de tu elección a 15 pies de él. Esa criatura recupera puntos de golpe iguales a tu modificador de Sabiduría.

#### Guía Ancestral
A partir del nivel 3, tus conjuros restaurativos son guiados por la mano de tus ancestros. Siempre que uses un conjuro de nivel 1 o superior para restaurar puntos de golpe a una criatura y saques un 1 o un 2 al lanzar el dado, puedes volver a tirar el dado y debes usar el nuevo resultado, incluso si es otro 1 o 2.

#### Fuerzas Anuladoras
A nivel 6, puedes canalizar los elementos para interrumpir el trabajo de los conjuros de otros. Cuando lanzas un conjuro que tiene como objetivo una criatura aliada, también puedes intentar poner fin a un efecto de conjuro que la esté afectando. Si el nivel de ranura del efecto es igual o menor que el nivel del conjuro que lanzas, el efecto termina. De lo contrario, debes realizar un chequeo de Sabiduría (CD 10 + el nivel del conjuro) para intentar ponerle fin.

Puedes usar esta característica dos veces. Recuperas los usos gastados al finalizar un descanso prolongado.

\columnbreak

<div style='margin-top:30px;'></div>

#### Don Elemental
Al alcanzar el nivel 14, puedes usar tu acción adicional para otorgar a una criatura a 30 pies de ti un don de tu Afinidad Elemental. En algún momento dentro de los siguientes 10 minutos, la criatura puede invocar al elemento y obtener sus beneficios.

Una vez que uses esta característica, no podrás usarla de nuevo hasta que completes un descanso prolongado.
<div style='margin-top:10px;'></div>

&nbsp;&nbsp;&nbsp; ***Aire.*** La criatura puede invocar este don cuando sea el objetivo de un ataque con arma, haciendo que la tirada de ataque falle. La criatura puede usar esta característica antes o después de la tirada, pero antes de que se aplique cualquier efecto de la tirada.

***Tierra.*** La criatura puede invocar este don cuando sea golpeada por un ataque, ganando un número de puntos de golpe temporales igual a tu nivel de chamán. Estos puntos de golpe duran hasta el final del próximo turno de la criatura.

***Fuego.*** La criatura puede invocar este don cuando sea golpeada por un ataque cuerpo a cuerpo, envolviendo al atacante en llamas. El atacante debe superar una tirada de salvación de Destreza o recibir daño por fuego igual a tu nivel de chamán.

***Agua.*** La criatura puede invocar este don cuando sea el objetivo de un ataque o conjuro. Hasta el final de su próximo turno, no puede ser objetivo de ningún ataque o conjuro, y el atacante debe elegir otro objetivo o perder su acción. La criatura sigue recibiendo daño de efectos como el conjuro *bola de fuego*.

#### Manantial
A nivel 20, te conviertes en una fuente de energías restaurativas mediante las fuerzas del Plano Elemental. Cuando normalmente lanzarías uno o más dados para restaurar puntos de golpe con un conjuro, en su lugar usas el número máximo posible para cada dado. Por ejemplo, en lugar de restaurar 2d6 puntos de golpe a una criatura, restauras 12 puntos de golpe.

<div class='footnote'>PARTE 1 | CLASES</div>
<img src='https://www.gmbinder.com/images/owfSJiy.jpg' style='position:absolute; top:590px; right:-200px; width:1000px' />
<img src='https://www.gmbinder.com/images/wvTUmvu.png' style='position:absolute; top:55px; right:0px; width:1000px' />

\pagebreakNum

<div style='margin-top:500px'></div>

<div style='margin-top:500px'></div>

## Brujo
*Imagina lo que podrías hacer si lideraras un grupo de chamanes que controlaran la fuente de sus poderes, en lugar de suplicar por ellos. Imagina si tuvieran sirvientes que pudieran luchar a su lado. Sirvientes que hacen huir a tus enemigos de puro terror. Chupar su magia como un mosquito en verano.*
<div style="text-align:Right"> 

<div style='margin-top:-4px;'></div>

*— Gul'dan*  </div>

<div style='margin-top:0px;'></div>

Un diablillo se escabulle detrás de la tunica de una joven humana, que sonríe mientras mezcla encantos mágicos con dulces palabras, doblegando a sus enemigos. Un orco brutal agita su mano en el aire, haciendo surgir llamas verdes y rojas. Con un destello, lanza una bola de fuego vil contra un elfo de la noche.
Alternando su mirada entre un tomo desgastado y glifos burdamente dibujados, un renegado comienza un canto lento mientras un portal demoníaco emerge del suelo.

Los brujos son buscadores del conocimiento oculto del multiverso. A través de su magia vil y grimorios secretos, se sumergen profundamente en las artes prohibidas.

### Artes Oscuras
Frente a los poderes demoníacos, la mayoría de los aventureros solo ve muerte y destrucción. Los brujos, en cambio, ven oportunidad, dominio y un camino claro hacia el poder mediante su oscura hechicería. Son hechiceros voraces que esclavizan demonios para cumplir sus órdenes. Algunos se ocultan a plena vista, presentándose como arcanistas de mente abierta mientras practican artes oscuras en secreto. Otros lo hacen abiertamente, en sectas que rápidamente se vuelven notorias en todas partes.

\columnbreak

<div style='margin-top:363px'></div>

### Portadores del Vil
Los brujos son portadores del destructivo vil, una forma de magia comúnmente asociada con los demonios y la Legión Ardiente. Es bien conocida por ser entrópica y extremadamente caótica, lo que ha llevado a que su práctica sea prohibida en la mayoría de las sociedades y que sus practicantes trabajen en secreto. 

Mientras que otras formas de magia tienen una fuente natural, del propio lanzador o otorgada a él, la magia vil es un pacto. Corrompe las mentes de los involucrados y profana la tierra que los rodea. Si sus demonios sometidos no fueran suficiente para asustar al pueblo común, el temor a lo que estos poderes pueden traer ciertamente lo haría.

### Exploradores de Secretos
Aunque los brujos no son inherentemente malvados, a menudo juran lealtad a causas nobles, su deseo de comprender estos poderes oscuros y dominar fuerzas demoníacas genera desconfianza incluso entre sus aliados. 

Miran al Vacío sin dudarlo, aprovechando el caos que vislumbran en su interior para causar estragos en la batalla; algunas de sus habilidades son alimentadas por las almas que han cosechado de sus víctimas. 

Explotan la magia de sombra y vil para manipular y degradar las mentes y cuerpos de sus enemigos. Llaman a fuegos infernales que caen del cielo, inmolando a sus oponentes, y convocan demonios indomables del Vacío Abisal para sembrar el caos.

### Creación de un Brujo
Al crear a tu brujo, piensa en cómo y por qué decidiste sumergirte en los secretos de la hechicería vil, uno de los poderes más grandes y volátiles entre los mortales. ¿Qué te llevó a ver potencial donde otros solo veían muerte? ¿Fuiste seducido por los poderes prometidos? ¿Hiciste un trato con un demonio o un habitante del vacío?

Quizás formas parte de una secta que ve el vil y la sombra como medios para un fin, o tal vez un simple gusto fue suficiente para llevarte a una adicción mágica que ahora luchas por superar. Cómo se desarrollaron tus oscuros estudios depende de ti.

<div class='footnote'>PARTE 1 | CLASES</div>
<img src='https://www.gmbinder.com/images/dvMcsXD.jpg' style='position:absolute; top:-0px; right:-100px; width:1100px;transform:scalex(-1)' />
<img src='https://www.gmbinder.com/images/vn90cy3.png' style='position:absolute; top:-10px; right:0px; width:800px; transform:scaleX(-1);' />
<img src='https://www.gmbinder.com/images/nZZkz5p.png' style='position:absolute; bottom:0px; right:0px; width:800px;' />
<img src='https://www.gmbinder.com/images/kWRapfL.png' style='position:absolute; top:24px; right:260px; width:550px;transform:scalex(-1)' />

\pagebreakNum

<div class="classTable wide" />

##### Brujo

Nivel   |Bonif.<br />Compet.|Características             |Conjuros<br />Truco Conocidos|Conjuros<br />Conocidos|Ranuras de<br />Conjuro|Nivel de<br />Ranura|Demonios<br />Conocidos|
--------|:-:|--------------------------------------------|:-:|:-----:|:-:|:-----:|:--:|
1.º     |+2 |Secretos Profanos, Hechicería Vil, Toque de Vida (1/día)|2  |2      |1  |1.º    |-
2.º     |+2 |Estudio Vil, Conocimiento Demoníaco          |2  |3      |2  |1.º    |1
3.º     |+2 |Fragmentos de Alma                           |2  |4      |2  |2.º    |1
4.º     |+2 |Mejora de Puntuación de Característica       |3  |5      |2  |2.º    |1
5.º     |+3 |Forja de Almas                              |3  |6      |2  |3.º    |2
6.º     |+3 |Característica de Estudio Vil                |3  |7      |2  |3.º    |2
7.º     |+3 |Toque de Vida (2/día)                        |3  |8      |2  |4.º    |3
8.º     |+3 |Mejora de Puntuación de Característica       |3  |9      |2  |4.º    |3
9.º     |+4 |Mejora de Fragmentos de Alma                 |3  |10     |2  |5.º    |4
10.º    |+4 |Característica de Estudio Vil                |4  |10     |2  |5.º    |4
11.º    |+4 |Nigromancia del Vacío (Nivel 6)              |4  |11+1   |3  |5.º    |4
12.º    |+4 |Mejora de Puntuación de Característica       |4  |11+1   |3  |5.º    |4
13.º    |+5 |Nigromancia del Vacío (Nivel 7)              |4  |12+2   |3  |5.º    |4
14.º    |+5 |Característica de Estudio Vil, Toque de Vida (3/día) |4  |12+2   |3  |5.º    |4
15.º    |+5 |Nigromancia del Vacío (Nivel 8)              |4  |13+3   |3  |5.º    |4
16.º    |+5 |Mejora de Puntuación de Característica       |4  |13+3   |3  |5.º    |4
17.º    |+6 |Nigromancia del Vacío (Nivel 9)              |4  |14+4   |4  |5.º    |4
18.º    |+6 |Característica de Estudio Vil                |4  |14+4   |4  |5.º    |4
19.º    |+6 |Mejora de Puntuación de Característica       |4  |15+4   |4  |5.º    |4
20.º    |+6 |Toque de Vida (a voluntad)                   |4  |15+4   |4  |5.º    |4

**Nota:** El "+X" representa conjuros de Nigromancia del Vacío.
</div>

#### Multiclase

***Caracteristica Minima.*** Debes tener al menos un 13 en Inteligencia para tomar un nivel en esta clase, o para tomar un nivel en otra clase si ya eres brujo.

***Competencias Adquiridas.*** Una habilidad de tu elección de las competencias de habilidades de brujo al coger tu primer nivel como brujo.

***Hechicería Vil.*** Puedes lanzar conjuros conocidos o preparados de la característica de clase Lanzamiento de Conjuros usando ranuras de conjuros de Hechicería Vil y viceversa.

#### Creación Rápida
Haz que la Inteligencia sea tu caracteristica principal, seguida de Constitución. Elige el trasfondo de charlatán. 

Elige los trucos *rayo de sombra* y *mano de mago*, junto con el conjuro de nivel 1 *piel de demonio* y uno de los conjuros de nivel 1 *drenar vida* o *rayo de brujería*.

\columnbreak

## Características de Clase

#### Puntos de Golpe
___
- **Dado de Golpe:** 1d8 por nivel de brujo
- **PG al nivel 1:** 8 + Mod. Constitución
- **PG por nivel:** 1d8 (o 5) + Mod. Constitución por cada nivel de brujo

#### Competencias
___
- **Armadura:** Ninguna
- **Armas:** Armas simples
- **Herramientas:** Ninguna
- **Tiradas de Salvación:** Constitución, Inteligencia
- **Habilidades:** Elige dos habilidades de Arcano, Engaño, Historia, Perspicacia, Intimidación, Percepción o Religión

#### Equipo
- cualquier arma simple
- *(a)* una bolsa de componentes o *(b)* un enfoque arcano
- *(a)* un paquete de erudito o *(b)* un paquete de explorador
- dos dagas y una bolsa de cinturón

<div class='footnote'>PARTE 1 | CLASES</div>

\pagebreakNum

### Secretos Profanos
*Característica de brujo de 1er nivel*

<div style='margin-top:-4px'></div>

Has pasado largas horas investigando y practicando conocimientos prohibidos, obteniendo los siguientes beneficios:
- Puedes hablar, leer y escribir en Eredun.
- Tienes ventaja en los chequeos de Inteligencia realizados para recordar información sobre aberraciones, demonios y no muertos.
- Aplicas tu bonificador de competencia cuando haces un chequeo de Carisma al interactuar con demonios, o el doble de tu bonificador de competencia si eres competente en la habilidad.

### Hechicería Vil
*Característica de brujo de 1er nivel*

<div style='margin-top:-4px'></div>

Tu investigación sobre conocimientos prohibidos te ha dado facilidad con la magia oscura. Consulta el capítulo 10 del Manual del Jugador para las reglas generales sobre lanzamiento de conjuros y el capítulo 6 para la lista de conjuros de brujo.

#### Trucos
Conoces dos trucos de tu elección de la lista de conjuros de brujo. Aprendes conjuros trucos adicionales a niveles superiores, como se muestra en la columna de Conjuros Conocidos de la tabla del Brujo.

#### Ranuras de Conjuros
La tabla del Brujo muestra cuántas ranuras de conjuros tienes. La tabla también muestra el nivel de esas ranuras; todas tus ranuras de conjuros son del mismo nivel. Para lanzar uno de tus conjuros de brujo de nivel 1 o superior, debes gastar una ranura de conjuros. Recuperas todas las ranuras de Hechicería Vil gastadas al finalizar un descanso breve o prolongado.

Por ejemplo, cuando eres de nivel 5, tienes dos ranuras de conjuros de nivel 3. Para lanzar el conjuro de nivel 1 *Rayo de Brujería*, debes gastar una de esas ranuras, y lo lanzas como un conjuro de nivel 3.

#### Conjuros Conocidos de Nivel 1 o Superior
A nivel 1, conoces dos conjuros de nivel 1 de tu elección de la lista de conjuros de brujo.

La columna de Conjuros Conocidos de la tabla del Brujo muestra cuándo aprendes más conjuros de brujo de tu elección de nivel 1 o superior. Un conjuro que elijas debe ser de un nivel no superior al que se muestra en la columna de Nivel de Ranura para tu nivel. Cuando alcances el nivel 6, por ejemplo, aprendes un nuevo conjuro de brujo, que puede ser de nivel 1, 2 o 3.

Además, cuando subas de nivel en esta clase, puedes elegir uno de los conjuros de brujo que conoces y reemplazarlo con otro conjuro de la lista de brujos, que también debe ser de un nivel para el que tengas ranuras de conjuros.

\columnbreak

#### Habilidad para Lanzar Conjuros
La Inteligencia es tu habilidad para lanzar conjuros de brujo, por lo que usas tu Inteligencia siempre que un conjuro haga referencia a tu habilidad para lanzar conjuros. Además, utilizas tu modificador de Inteligencia para establecer la CD de salvación de los conjuros de brujo que lances y al hacer una tirada de ataque con uno.

<div style="text-align: center">

**CD de salvación de conjuros** = 8 + Bonus Competencia + Mod. Inteligencia

**Modificador de ataque de conjuros** = Bonus Competencia + Mod. Inteligencia
</div>

#### Lanzamiento Ritual
Puedes lanzar un conjuro de brujo como ritual si ese conjuro tiene la etiqueta de ritual y lo conoces.

#### Enfoque para Lanzar Conjuros
Puedes usar un enfoque arcano como enfoque para lanzar tus conjuros de brujo.

### Toque de Vida
*Característica de brujo de 1er nivel*

<div style='margin-top:-4px'></div>

Cuando no tienes ranuras de Hechicería Vil restantes, aún puedes lanzar un conjuro como si las tuvieras. Como parte de la acción para lanzar el conjuro, pierdes puntos de golpe iguales a tu nivel más el nivel de la ranura de Hechicería Vil. Por ejemplo, un brujo de nivel 7 con ranuras de conjuros de nivel 4 gastaría 11 puntos de golpe para lanzar un conjuro de nivel 4.

Este daño no puede ser resistido y no puedes usar esta característica si hacerlo te reduciría a 0 puntos de golpe. Puedes usar esta habilidad una vez a nivel 1, dos veces a nivel 7, tres veces a nivel 14 y un número ilimitado de veces a nivel 20. Recuperas todos los usos gastados al finalizar un descanso prolongado.

### Estudio Vil
*Característica de brujo de 2.º nivel*

<div style='margin-top:-4px'></div>

Elige tu campo de estudio: Estudio de la Aflicción, Estudio de la Demonología o Estudio de la Destrucción, cada uno de los cuales se detalla al final de la descripción de la clase. Tu elección te otorga características a los niveles 6, 10, 14 y 18.

<div class='footnote'>PARTE 1 | CLASES</div>

\pagebreakNum

### Conocimiento Demoníaco
*Característica de brujo de 2.º nivel*

<div style='margin-top:-4px'></div>

Tus estudios en grimorios de conocimiento oscuro te han otorgado el poder de invocar demonios. Puedes recurrir a los principios del **Grimorio de Servidumbre** para atarlos como tu minion demoníaco o al **Grimorio de Sacrificio** para arrancarles su núcleo demoníaco.

La invocación de un demonio solo puede realizarse al final de un descanso prolongado. Solo puedes tener un minion demoníaco o un núcleo a la vez.

#### Demonios Conocidos
Comienzas sabiendo cómo invocar un tipo particular de demonio de tu elección. La columna de Demonios Conocidos de la tabla del Brujo muestra cuándo aprendes tipos adicionales de demonios. Cada vez que subas de nivel en esta clase, puedes elegir reemplazar un demonio que conozcas.

Los demonios y sus núcleos se describen en la Parte I del Apéndice C.

#### Grimorio de Sacrificio
Usando el Grimorio de Sacrificio, puedes destruir un demonio cuando lo invocas para obtener su núcleo demoníaco, la fuente de su poder. Un núcleo demoníaco varía de un demonio a otro.

A nivel 2, mientras llevas el núcleo tienes ventaja en dos chequeos de habilidad. Al sostener el núcleo, conoces un conjuro o truco adicional. Puedes lanzar este conjuro a voluntad.

A medida que aumentas de nivel, puedes profundizar en el núcleo para lanzar conjuros más poderosos. A los niveles 5 y 9, ganas un conjuro adicional conocido mientras llevas el núcleo. Puedes lanzar estos conjuros una vez cada uno sin gastar una ranura de conjuro y recuperas la habilidad para hacerlo cuando termines un descanso prolongado.

A nivel 13, puedes consumir el núcleo como una acción para recargar tus propios poderes, recuperando todos los fragmentos de alma gastados.

Las habilidades afectadas y los conjuros proporcionados varían según el demonio del que provenga el núcleo. Consulta la sección de Núcleos Demoníacos de cada demonio en la Parte I del Apéndice C para obtener más detalles.

\columnbreak

#### Grimorio de Servidumbre
Usando el Grimorio de Servidumbre, puedes atar a un demonio para que se convierta en tu minion. Tu minion actúa independientemente de ti, pero siempre obedece tus órdenes. Consulta la Parte I del Apéndice C para las estadísticas del juego del demonio.

Una vez invocado, un minion demoníaco permanece hasta que sea destruido o despedido. Puedes despedir temporalmente a tu minion como una acción. Desaparece en una dimensión de bolsillo donde espera tu llamada. Alternativamente, puedes despedirlo para siempre. Como una acción mientras está temporalmente despedido, puedes hacer que reaparezca en cualquier espacio desocupado a 30 pies de ti.

Cuando el minion cae a 0 puntos de golpe, desaparece, sin dejar forma física. Si el demonio ha muerto en la última hora, puedes gastar un fragmento de alma como una acción para revivirlo, siempre que estés a 5 pies de él. El demonio vuelve a la vida después de 1 minuto con todos sus puntos de golpe restaurados.

En combate, comparte tu iniciativa y toma su turno inmediatamente después del tuyo. Puede moverse y usar su reacción por sí mismo, pero la única acción que toma en su turno es la acción de Esquivar, a menos que uses tu acción adicional en tu turno para ordenarle que tome una de las acciones de su bloque de estadísticas o las acciones de Correr, Desengancharse, Ayudar, Esconderse o Buscar.

### Fragmentos de Alma
*Característica de brujo de nivel 3*

<div style='margin-top:-4px'></div>

Puedes crear fragmentos de alma: pequeños cristales formados a partir de fragmentos de almas y espíritus. Puedes gastar un fragmento de alma para potenciar tus conjuros y habilidades de brujo. Comienzas conociendo las habilidades listadas a continuación y aprendes más a medida que avanzas de nivel en la clase de brujo.

Puedes tener hasta tres fragmentos de alma en cualquier momento; intentar crear un fragmento de alma adicional resulta en una gema inútil y opaca. Los fragmentos de alma duran hasta que se usan, momento en el que desaparecen. Si un fragmento de alma sale de tu posesión durante al menos 8 horas, desaparece. Los fragmentos de alma que creas solo pueden ser utilizados por ti; los fragmentos creados por otros brujos son inútiles.

Durante el transcurso de un descanso, puedes recolectar fragmentos de almas errantes para crear fragmentos de alma. Puedes crear un solo fragmento de alma durante un descanso breve o cualquier cantidad durante un descanso prolongado.

<img src='https://www.gmbinder.com/images/8GHYm5P.jpg' style='position:absolute; top:770px; right:0px; width:800px' />
<img src='https://www.gmbinder.com/images/3e9S91s.png' style='position:absolute; top:0px; right:-15px; width:825px' />
<img src='https://www.gmbinder.com/images/pZ94Ass.png' style='position:absolute; top:780px; right:400px; width:350px' />

<div class='footnote footnote-white'>PARTE 1 | CLASES</div>

\pagebreakNum

<div style='margin-top:-9px'></div>

> ##### Fragmentos de Almas de Criaturas
> Los fragmentos de alma solo son útiles si se crean a partir de energía espiritual suficientemente densa o almas complejas. Aunque existen algunas excepciones, las siguientes directrices suelen ser ciertas:
> - Todos los humanoides pueden producir fragmentos de alma.
> - La mayoría de los no muertos y casi todos los constructos no pueden producir fragmentos de alma.
> - Todos los demás tipos de criaturas generalmente solo producen fragmentos de alma si sus almas son lo suficientemente complejas: i.e., su CR es de 1/8 o superior.

Además, puedes capturar parte de las almas que escapan de las criaturas moribundas cercanas en forma de fragmentos de alma. Cuando una criatura apropiada a 60 pies de ti muere, puedes usar tu reacción para crear un fragmento de alma.

Cuando alcanzas el nivel 9, tu cantidad máxima de fragmentos de alma aumenta a cinco.

Lo que constituye una criatura apropiada queda a discreción del DM, pero hay una guía en el recuadro **Fragmentos de Almas de Criaturas**.

Puedes gastar un fragmento de alma a 5 pies de ti para crear uno de los siguientes efectos:

***Círculo de Conjuros.*** Puedes gastar un fragmento de alma como una acción adicional para crear un círculo de runas demoníacas de 5 pies de radio en el suelo. Mientras permanezcas en este círculo, tienes ventaja en los chequeos de concentración. El círculo desaparece después de 1 minuto.

***Quemar Alma: Extender.*** Cuando lances un conjuro con una duración de 1 hora o más, puedes gastar un fragmento de alma para extender su duración un número de horas igual a tu nivel de brujo.

***Quemar Alma: Acelerar.*** Cuando lances un conjuro con un tiempo de lanzamiento de 10 minutos o menos, puedes gastar un fragmento de alma para lanzarlo como una acción.

***Quemar Alma: Rebotar.*** Cuando lances un conjuro que afecte a un solo objetivo y no tenga efecto (ya sea por fallar en la tirada de ataque o porque el objetivo tuvo éxito en su tirada de salvación), puedes gastar un fragmento de alma como reacción para redirigirlo a otro objetivo dentro de su alcance.

***Ritos de Alma.*** Puedes gastar un fragmento de alma para lanzar cualquier conjuro de brujo con la etiqueta de ritual como ritual siempre que tengas ranuras de Hechicería Vil o Nigromancia del Vacío del nivel indicado del conjuro. No necesitas conocer el conjuro para lanzarlo como ritual mientras esté en la lista de conjuros de brujo.

\columnbreak

### Mejora de Característica
*Característica de brujo de nivel 4*

<div style='margin-top:-4px'></div>

Cuando alcanzas el nivel 4, y nuevamente en los niveles 8, 12, 16 y 19, puedes aumentar una puntuación de característica de tu elección en 2, o puedes aumentar dos puntuaciones de característica de tu elección en 1. Como es habitual, no puedes aumentar una puntuación de característica por encima de 20 con esta característica.

### Forjado de Almas
*Característica de brujo de nivel 5*

<div style='margin-top:-4px'></div>

Puedes forjar piedras mágicas poderosas a partir de tus fragmentos de alma. Creas una piedra gastando un fragmento de alma, lo cual se realiza como una acción. Una vez creada, la piedra dura hasta que se usa, momento en el cual se desintegra en polvo. Solo puedes tener una piedra de cada tipo creada al mismo tiempo; crear una piedra adicional hará que la otra se vuelva inerte.

***Piedra de Fuego.*** Puedes gastar esta piedra al lanzar un conjuro de brujo para hacer que inflija un golpe crítico con una tirada de 19 o 20. Si el conjuro no usa una tirada de ataque, inflige daño como si fuera un nivel de conjuro superior.

***Piedra de Salud.*** Tú u otra criatura pueden aplastar la piedra de salud como una acción para recuperar un número de puntos de golpe igual a tu modificador de Inteligencia + tu nivel de brujo.

***Piedra de Alma.*** Puedes gastar esta piedra para lanzar el conjuro *reanimar* sin gastar una ranura de conjuro ni proporcionar componentes materiales. Si te reducen a 0 puntos de golpe y llevas una piedra de alma, se gasta automáticamente y en su lugar te quedas con 1 punto de golpe.

***Piedra de Conjuro.*** Puedes gastar esta piedra al lanzar un conjuro de brujo, haciendo que una criatura tenga desventaja en su primera tirada de salvación contra dicho conjuro.

### Nigromancia del Vacío
*Característica de brujo de nivel 11*

<div style='margin-top:-4px'></div>

Puedes forzarte a lanzar conjuros más poderosos un cierto número de veces por día. Obtienes una ranura de conjuro de nivel 6. Esta ranura puede gastarse para lanzar cualquier conjuro de brujo que conozcas. Recuperas cualquier ranura de conjuros de Nigromancia del Vacío gastada al finalizar un descanso prolongado.

Cada vez que obtengas una ranura de conjuro mediante Nigromancia del Vacío, también aprendes un solo conjuro de brujo de un nivel que puedas lanzar. Estos se cuentan por separado de tus conjuros normales, como se muestra en la columna de Conjuros Conocidos de la tabla del Brujo.

A niveles superiores. obtienes más ranuras de conjuro: una ranura de conjuro de nivel 7 a nivel 13, una de nivel 8 a nivel 15 y una de nivel 9 a nivel 17.

Cuando subas de nivel en esta clase, puedes elegir uno de los conjuros de brujo obtenidos mediante Nigromancia del Vacío y reemplazarlo con otro conjuro de la lista de conjuros de brujo.

\pagebreakNum

## Estudios Viles
Los brujos han entrado en contacto con el poderoso vil, estudiando su energía incontrolable. Existen tres estudios, cada uno profundizando en un aspecto diferente de los poderes manejados por los brujos.

### Estudio de la Aflicción
Los brujos que estudian la aflicción se convierten en maestros de los poderes tocados por la sombra. A diferencia de los sacerdotes de la Senda de las Sombras, los brujos disfrutan usando el vil como una fuerza para infligir dolor, dejando a sus enemigos en torbellinos de tormento.

#### Lista Ampliada de Conjuros
*Característica de Estudio de la Aflicción de nivel 2*

<div style='margin-top:-4px'></div>

Tu área de estudio te permite elegir de una lista ampliada de conjuros cuando aprendes un conjuro de brujo. Los siguientes conjuros se añaden a la lista de conjuros de brujo para ti.

##### Conjuros Ampliados de Aflicción
Nivel de<br />Conjuro|Conjuros
----------------|------
1.º|✦ *vacío oscuro*, *susurros disonantes*
2.º|*ceguera/sordera*, ✦ *descarga mental*
3.º|*ralentizar*, *nube apestosa*
4.º|*confusión*, *maldición elemental ^XGE^*
5.º|*nube aniquiladora*, *contagio*

#### Corrupción
*Característica de Estudio de la Aflicción de nivel 2*

<div style='margin-top:-4px'></div>

Puedes lanzar Maldiciones, que son poderosas maldiciones que puedes colocar sobre las criaturas. Aprendes una Maldición de tu elección, que se detalla en "Maldiciones" más adelante. Aprendes una Maldición adicional de tu elección y puedes reemplazar una de las Maldiciones que conozcas por otra en los niveles 6, 10, 14 y 18.

Cuando uses tu Corrupción, eliges qué Maldición invocar. Al invocar una Maldición, pero antes de que afecte al objetivo, puedes elegir amplificar la maldición gastando un fragmento de alma. Una maldición amplificada obtiene un efecto adicional, descrito en la descripción de la maldición. Si una Maldición requiere una tirada de salvación, usa la CD de salvación de tus conjuros de brujo.

Puedes usar esta característica una vez. A partir del nivel 6, puedes usar tu característica de Corrupción dos veces; a nivel 14, puedes usarla tres veces entre descansos, y a nivel 18, puedes usarla cuatro veces entre descansos. Recuperas todos los usos gastados al finalizar un descanso breve o prolongado.

\columnbreak

#### Acechar
*Característica de Estudio de la Aflicción de nivel 2*

<div style='margin-top:-4px'></div>

Cuando una criatura a 60 pies hace un chequeo de habilidad usando Carisma, Inteligencia o Sabiduría, puedes usar tu reacción para manifestar una presencia demoníaca a su alrededor. La criatura es acechada, su mente nublada por esta presencia.

El objetivo debe hacer una tirada de salvación de Sabiduría contra la CD de salvación de tus conjuros de brujo. Si falla, el chequeo de habilidad también falla. Si el objetivo realiza otro chequeo de habilidad usando la misma puntuación de habilidad mientras está acechado, debe repetir la tirada de salvación.

Si tiene éxito en la tirada de salvación, el acecho termina y el chequeo de habilidad se realiza con normalidad. Una vez que uses esta habilidad, no puedes volver a hacerlo hasta que termines un descanso breve.

#### Maestro de Maldiciones
*Característica de Estudio de la Aflicción de nivel 6*

<div style='margin-top:-4px'></div>

Aprendes los conjuros *Imponer maldición* y *Levantar maldición*. Estos no cuentan para el número de conjuros conocidos listados en la tabla del Brujo.

Cuando lances cualquiera de estos conjuros puedes elegir hasta dos criaturas como objetivo en lugar de una.

#### Drenar Alma
*Característica de Estudio de la Aflicción de nivel 10*

<div style='margin-top:-4px'></div>

Cuando inflijas daño psíquico o necrótico a una criatura, puedes generar un fragmento de alma. Puedes usar esta habilidad tres veces y recuperas todos los usos gastados cuando terminas un descanso prolongado.

#### Aflicciones Inestables
*Característica de Estudio de la Aflicción de nivel 14*

<div style='margin-top:-4px'></div>

Cuando una criatura tenga éxito en una tirada de salvación contra uno de tus conjuros o habilidades de brujo, recibe daño psíquico igual a la mitad de tu nivel de brujo.

#### Aflicciones Potentes
*Característica de Estudio de la Aflicción de nivel 18*

<div style='margin-top:-4px'></div>

Elige una de las siguientes opciones. Una vez que uses cualquiera de estas habilidades, no podrás volver a hacerlo hasta que completes un descanso largo.

***Maldicion del Destino.*** Aprendes una maldición de destino inminente. Como una acción adicional, colocas la maldición sobre una criatura que puedas ver a 60 pies. Al final de cada turno de la criatura, el objetivo recibe 1d4 puntos de daño psíquico. Este daño aumenta en 1 por cada turno después del primero.

Después de que el objetivo reciba daño de esta maldición seis veces, o cuando la criatura muera, aparece un guardia apocalíptico a 5 pies del objetivo maldito, o en el espacio disponible más cercano.

El guardia apocalíptico actúa en el turno inmediatamente posterior al tuyo y obedece tus órdenes (sin requerir acción) durante 1 minuto o hasta que sea destruido o desechado como acción adicional, después de lo cual desaparece. Los guardias apocalípticos se describen en la Parte II del Apéndice C.

<img src='https://www.gmbinder.com/images/p23X3P4.png' style='position:absolute; width:800px; bottom:-7px; right:0px;' />

<div class='footnote footnote-white'>PARTE 1 | CLASES</div>


\pagebreakNum


***Semilla de Corrupción.*** Aprendes a colocar un fragmento de energía de sombra dentro de una criatura, que crece hasta detonar. Como acción adicional, puedes colocar la maldición sobre una criatura que puedas ver a 60 pies.

La criatura recibe 1d6 puntos de daño psíquico al inicio de su turno. Este daño aumenta en 1d6 cada turno después del primero. La criatura puede intentar una salvación de Sabiduría al final de su turno, terminando el efecto si realiza dos salvaciones exitosas.

Cuando la maldición finaliza, ya sea porque la criatura muera o logre su salvación, un número de criaturas de tu elección a 60 pies de distancia, hasta el número de dados de daño psíquico lanzados por esta maldición, deben realizar una tirada de salvación de Sabiduría contra la CD de tus conjuros de brujo o ganar una maldición de tu elección del conjuro *Imponer maldición*. Si el objetivo muere como resultado del daño de esta habilidad, las criaturas tienen desventaja en sus tiradas de salvación.

La misma maldición debe aplicarse a todas las criaturas afectadas. Esta maldición dura 24 horas, a menos que sea eliminada. Intentar hacerlo requiere un chequeo de habilidad contra la CD de tus conjuros de brujo para tener éxito.

#### Maldiciones
Las maldiciones se presentan en orden alfabético.

<div style='margin-top:-5px'></div>

##### Maldición de la Agonía
Como acción adicional, maldices a una criatura que puedes ver a 30 pies, infligiendo 1d4 puntos de daño psíquico. Durante cada uno de tus turnos durante el próximo minuto, puedes usar tu acción adicional para infligir 1d4 de daño psíquico a la criatura. Este daño aumenta con el nivel: 2d4 a nivel 5, 3d4 a nivel 11 y 4d4 a nivel 17. La criatura puede intentar una salvación de Sabiduría al inicio de su turno, terminando el efecto en caso de éxito.

***Ampliar.*** Cuando el objetivo reciba daño por la Maldición, tiene desventaja en la próxima tirada de ataque que haga antes del final de su próximo turno.

##### Maldición de los Elementos
Cuando una criatura que puedes ver a 30 pies sea golpeada por un ataque o conjuro, puedes usar tu reacción para debilitar temporalmente su resistencia al mismo. Hasta el final del turno, el objetivo pierde su resistencia a los tipos de daño del ataque o conjuro desencadenante.

***Ampliar.*** El objetivo pierde en su lugar la inmunidad a los tipos de daño del ataque o conjuro desencadenante, obteniendo resistencia hasta el final del turno.

##### Maldición de Agotamiento
Como acción adicional, puedes intentar agotar a una criatura que puedas ver a 30 pies de ti. El objetivo debe tener éxito en una tirada de salvación de Constitución o su velocidad se reduce a 0 y no puede usar reacciones hasta el final de tu próximo turno.

***Ampliar.*** Esta maldición dura 1 minuto. Al final de cada uno de sus turnos, la criatura maldita puede realizar otra tirada de salvación de Constitución. Con éxito, la maldición termina.

\columnbreak

##### Maldición de Fragilidad
Como acción adicional, puedes intentar maldecir a una criatura que puedas ver a 30 pies. La criatura no puede recuperar puntos de golpe hasta el final de su próximo turno. Además, cualquier punto de golpe temporal que posea se elimina. Cuando el efecto termina, recupera los puntos de golpe temporales que poseía.

***Ampliar.*** La maldición dura 1 minuto. Al final de cada uno de sus turnos, la criatura maldita puede realizar una tirada de salvación de Sabiduría. Con éxito, la maldición termina.

##### Maldición de la Imprudencia
Cuando una criatura que puedes ver a 30 pies realiza una tirada de ataque, puedes usar tu reacción para hacer que ataque imprudentemente. Hasta el inicio de su próximo turno, los ataques contra la criatura tienen ventaja.

***Ampliar.*** Durante 1 minuto, el objetivo no puede usar las acciones de Desengancharse, Esquivar o Esconderse. La criatura puede intentar una salvación de Sabiduría al final de cada uno de sus turnos, terminando el efecto en caso de éxito.

##### Maldición de las Sombras
Como acción adicional, maldices a una criatura que puedes ver a 30 pies hasta el inicio de tu próximo turno. La primera vez que la criatura reciba daño en un turno, recibe un daño adicional de 1d8 puntos de daño necrótico. Cuando la criatura recibe este daño extra, puede intentar una tirada de salvación de Sabiduría contra la CD de tus conjuros de brujo, terminando el efecto en caso de éxito.

***Ampliar.*** La maldición dura 1 minuto.

##### Maldición de las Lenguas
Cuando una criatura que puedes ver a 30 pies intente lanzar un conjuro con un componente verbal, puedes usar tu reacción para intentar interrumpirlo con una maldición. La criatura debe usar su propia reacción para tener éxito al lanzar el conjuro. Hasta el final del siguiente turno de la criatura, no puede hablar ningún idioma que conozca.

***Ampliar.*** La maldición dura 1 minuto. La criatura debe usar una acción adicional o reacción cada vez que intente lanzar un conjuro, o el conjuro falla y se desperdicia. La criatura puede intentar una tirada de salvación de Inteligencia al final de cada uno de sus turnos, terminando el efecto en caso de éxito.

<div class='footnote'>PARTE 1 | CLASES</div>

##### Maldición de la Debilidad
Como acción adicional, maldices a una criatura que puedes ver a 30 pies hasta el inicio de tu próximo turno. Siempre que la criatura impacte con un ataque de arma, lanza dos veces para el daño y toma el resultado más bajo.

***Ampliar.*** La maldición dura 1 minuto. La criatura puede intentar una tirada de salvación de Constitución al inicio de tu turno, finalizando el efecto si tiene éxito.

\pagebreakNum

### Estudio de Demonología
Los brujos que estudian demonología aprovechan los poderes de los seres demoníacos del Vacío Abisal. Descubren secretos desconocidos para los habitantes de Azeroth y tuercen su magia con la ayuda de poderes demoníacos del Gran Oscuro.

#### Lista Ampliada de Conjuros
*Característica de Estudio de Demonología de nivel 2*

<div style='margin-top:-4px'></div>

Tu área de estudio te permite elegir de una lista ampliada de conjuros cuando aprendes un conjuro de brujo. Los siguientes conjuros se añaden a la lista de conjuros de brujo para ti.

##### Conjuros Ampliados de Demonología
Nivel de<br />Conjuro|Conjuros
----------------|------
1.º|*mandato*, *protección contra el bien y el mal*
2.º|*augurio*, *arma espiritual*
3.º|*círculo mágico*, *guardianes espirituales*
4.º|*puerta dimensional*, *dominar bestia*
5.º|*llamada infernal ^XGE^*, *atadura planar*

#### Conducto de Almas
*Característica de Estudio de Demonología de nivel 2*

<div style='margin-top:-4px'></div>

Tus estudios en demonología te permiten formar un vínculo más fuerte entre tú y tus esbirros demoníacos. Puedes comunicarte telepáticamente con tu minion siempre que estén en el mismo plano de existencia.

Además, como acción, puedes ver a través de sus ojos y oír lo que oye hasta el inicio de tu próximo turno, obteniendo los beneficios de cualquier sentido especial que tenga el demonio. Durante este tiempo, eres sordo y ciego con respecto a tus propios sentidos.

Mientras percibes a través de los sentidos de tu minion, también puedes hablar a través de él con tu propia voz, incluso si tu compañero normalmente es incapaz de hablar.

Finalmente, cuando lanzas un conjuro con un alcance de toque, tu compañero demoníaco puede entregar el conjuro como si lo hubiera lanzado. Tu compañero debe estar a 100 pies de ti y usar su reacción para entregar el conjuro cuando lo lanzas. Si el conjuro requiere una tirada de ataque, usas tu modificador de ataque para la tirada.

#### Sentir Demonios
*Característica de Estudio de Demonología de nivel 2*

<div style='margin-top:-4px'></div>

Ganas la capacidad de detectar la presencia de demonios gracias a tu sensibilidad hacia las energías demoníacas. Como acción, puedes abrir tu conciencia para detectar mágicamente demonios. Hasta el final de tu próximo turno, conoces la ubicación de cualquier demonio a 60 pies de ti que no esté detrás de cobertura total ni protegido contra la magia de adivinación. Este sentido no te dice nada sobre las capacidades o identidad de la criatura.

Puedes usar esta característica un número de veces igual a tu modificador de Inteligencia (mínimo una vez). Recuperas todos los usos gastados al finalizar un descanso prolongado.

\columnbreak

#### Vínculo de Almas
*Característica de Estudio de Demonología de nivel 6*

<div style='margin-top:-4px'></div>

Mientras el demonio esté a 60 pies de ti, la mitad<br /> de cualquier daño que recibas (redondeado hacia arriba) se transfiere al compañero demoníaco.

Además, tu compañero demoníaco puede usar su reacción en lugar de la tuya para generar un fragmento de alma.

#### Furia Demoníaca
*Característica de Estudio de Demonología de nivel 10*

<div style='margin-top:-4px'></div>

Obtienes un conjunto de energía que puedes usar para potenciar a tu demonio. Tienes seis puntos que puedes usar para obtener uno de los siguientes efectos, y recuperas los puntos gastados cuando terminas un descanso prolongado:
- Cuando ordenes a tu demonio que realice la acción de ataque, puedes gastar un punto para darle ventaja en la tirada de ataque.
- Cuando tu demonio sea forzado a realizar una tirada de salvación, puedes gastar un punto como reacción para darle ventaja en la tirada.

#### Grimorio de Supremacía
*Característica de Estudio de Demonología de nivel 14*

<div style='margin-top:-4px'></div>

Puedes recurrir al conocimiento del Grimorio de Supremacía para evolucionar permanentemente a tu minion demoníaco en una forma más poderosa. Gana una serie de beneficios mencionados en su entrada en la Parte I del Apéndice C.

#### Somos Legión
*Característica de Estudio de Demonología de nivel 18*

<div style='margin-top:-4px'></div>

Aplicas las enseñanzas del Grimorio de Supremacía a ti mismo, transformándote permanentemente en un demonio. Puedes ganar dos o más peculiaridades de la tabla de Peculiaridades de la Metamorfosis (o inventar peculiaridades similares) y las siguientes habilidades:

- Te brotan alas que te otorgan velocidad de vuelo igual a tu velocidad de movimiento. Puedes ocultar o mostrar estas alas como acción adicional.
- Ganas resistencia al daño de fuego y necrótico.
- No envejeces, ni necesitas comer, beber o dormir.
- Los demonios con una inteligencia de 3 o menos no te atacarán a menos que tú los ataques.

##### Peculiaridades de la Metamorfosis
d8|Peculiaridad
--|--
1|Tus ojos se vuelven verdes y brillan en la oscuridad.
2|Tu piel se torna verde o roja.
3|Tus dientes se convierten en colmillos o colmillos y tus uñas se parecen a garras negras.
4|Te brotan cuernos de la frente.
5|Tu piel desarrolla espinas o se vuelve escamosa.
6|Pareces haber envejecido varias décadas, aunque esto no reduce tu esperanza de vida.
7|Tu sangre se vuelve verde brillante y emite un tenue brillo.
8|Tu cuerpo se deforma, dándote una apariencia encorvada y una cojera.

<div class='footnote'>PARTE 1 | CLASES</div>

\pagebreakNum

### Estudio de la Destrucción
Los brujos que estudian la destrucción manipulan el concepto metafísico de la destrucción, dispuestos a sufrir el retroceso si les permite causar más caos entre sus enemigos. Se deleitan con la destrucción que provocan, emocionados ante cualquier oportunidad de ver el mundo estallar en discordia.

#### Lista Ampliada de Conjuros
*Característica de Estudio de la Destrucción de nivel 2*

<div style='margin-top:-4px'></div>

Tu área de estudio te permite elegir de una lista ampliada de conjuros cuando aprendes un conjuro de brujo. Los siguientes conjuros se añaden a la lista de conjuros de brujo para ti.

##### Conjuros Ampliados de Destrucción
Nivel de<br />Conjuro|Conjuros
----------------|------
1.º|*manos ardientes*, *rayo del caos ^XGE^*
2.º|*esfera de fuego*, *romper*
3.º|*tierra eruptiva ^XGE^*, *bola de fuego*
4.º|*escudo de fuego*, *muro de fuego*
5.º|*onda destructiva*, *golpe de llama*

#### Piromaníaco
*Característica de Estudio de la Destrucción de nivel 2*

<div style='margin-top:-4px'></div>

Aprendes el truco *producir llama*, que cuentas como un truco de brujo y no cuenta contra tus trucos conocidos.

Además, puedes encender mágicamente un objeto inflamable que toques con tu mano como una acción.

#### Canalizar Fuego Demoníaco
*Característica de Estudio de la Destrucción de nivel 2*

<div style='margin-top:-4px'></div>

Puedes canalizar el poder de las llamas infernales en tus conjuros. Cuando infliges daño con un conjuro de brujo, puedes optar por recibir una cantidad de daño por fuego hasta tu nivel de brujo. Un objetivo recibe el doble de daño por fuego del que tú recibiste.

#### Caos
*Característica de Estudio de la Destrucción de nivel 6*

<div style='margin-top:-4px'></div>

Cuando lanzas un conjuro de brujo usando una ranura de Hechicería Vil que solo tenga un objetivo y no tenga un rango de "personal", puedes gastar un fragmento de alma para que el mismo conjuro tenga como objetivo a una segunda criatura en el rango.

#### Resolución Inquebrantable
*Característica de Estudio de la Destrucción de nivel 10*

<div style='margin-top:-4px'></div>

Cuando reduces a una criatura hostil a 0 puntos de golpe, obtienes puntos de golpe temporales igual a tu modificador de Inteligencia + tu nivel de brujo (mínimo de 1).

#### Llamas de Xerrath
*Característica de Estudio de la Destrucción de nivel 14*

<div style='margin-top:-4px'></div>

Puedes sobrecargar el poder de tus conjuros con las llamas viles. Cuando inflijas daño con un conjuro de brujo lanzado con una ranura de Hechicería Vil, puedes hacer que el conjuro inflija su daño máximo.

\columnbreak

La primera vez que lo hagas, no sufres ningún efecto adverso. Si usas esta característica de nuevo antes de completar un descanso prolongado, recibes 5d12 puntos de daño por fuego al final de tu turno actual. Cada vez que uses esta característica de nuevo antes de completar un descanso prolongado, el daño por fuego aumenta en 1d12. Este daño ignora la resistencia e inmunidad.

#### Infierno
*Característica de Estudio de la Destrucción de nivel 18*

<div style='margin-top:-4px'></div>

Puedes conjurar un meteorito del Vacío Abisal como una acción, haciendo que aparezca en el aire y se estrelle en un punto que designes dentro de 60 pies.

Las criaturas en un radio de 30 pies de ese punto reciben 2d8 puntos de daño contundente y 2d6 puntos de daño por fuego, y el suelo se convierte en terreno difícil. Luego, puedes elegir detonar la piedra, infligiendo 13d10 puntos de daño por fuego a todas las criaturas dentro de 30 pies del punto (salvación de Destreza para mitigar a la mitad), o puedes animarla como un infernal. Los infernales se describen en la Parte II del Apéndice C.

El infernal se levanta del cráter al final de tu turno, siguiendo tus órdenes (sin requerir acción). Permanece animado durante 1 minuto, o hasta que sea destruido o desechado como una acción adicional. Cuando deseches al infernal, puedes elegir si simplemente lo despides o lo fuerzas a usar su habilidad de Explosión de Muerte.

Una vez que hayas usado esta habilidad, no puedes volver a hacerlo hasta que completes un descanso prolongado.

<div class='footnote'>PARTE 1 | CLASES</div>
<img src='https://www.gmbinder.com/images/Zvvr01c.jpg' style='position:absolute; bottom:-85px; right:-70px; width:550px '/>
<img src='https://www.gmbinder.com/images/i9dzMuI.png' style='position:absolute; bottom:-270px; right:-30px; width:900px;' />
<img src='https://www.gmbinder.com/images/i9dzMuI.png' style='position:absolute; top:0px; right:-30px; width:900px;' />

\pagebreakNum
# Capítulo 6: Conjuros
Si bien la mayoría de las descripciones de conjuros se encuentran en el Manual del Jugador, algunos conjuros están descritos en otros lugares, como se indica en la tabla a continuación.

Símbolo|Ubicación del conjuro
------|-------------------------
✦     |     Descripciones de Conjuros
^W^ | Guía de Exploradores de Wildemount
^T^ | Caldero de Todo de Tasha
^X^ | Guía de Xanathar para Todo

\pagebreakNum

## Conjuros de Brujo
<div style='column-count:2'>

##### Trucos (Nivel 0)
Salpicadura Ácida
<br /> Hoja Afilada
<br /> Toque Helado
<br /> Crear Hoguera ^X^
<br /> ✦ Diabolismo
<br /> ✦ Llama Vil
<br /> Rayo de Fuego
<br /> Hoja Verde Llameante ^T^
<br /> Mano Mágica
<br /> Producir Llama
<br /> Zancada Desfallecedora ^W^
<br /> ✦ Rayo de Sombra
<br /> Llamada de la Tumba ^X^

##### 1er Nivel
Alarma
<br /> Brazos de Hadar
<br /> Maldición
<br /> Causar Miedo ^X^
<br /> Orbe Cromático
<br /> Comprender Idiomas
<br /> ✦ Piel Demoníaca
<br /> Detectar Magia
<br /> ✦ Drenar Vida
<br /> Retirada Expeditiva
<br /> Falsa Vida
<br /> Encontrar Familiar
<br /> Réplica Infernal
<br /> Execrar
<br /> Identificar
<br /> Escritura Ilusoria
<br /> Saltar
<br /> Rayo de Enfermedad
<br /> Escudo
<br /> Dormir
<br /> Brebaje Cáustico de Tasha ^T^
<br /> Risa Histérica de Tasha
<br /> Criado Invisible
<br /> Rayo de la Bruja

##### 2.º Nivel
Azote de Aganazzar ^X^
<br /> Alterar el Ser
<br /> Cerradura Arcana
<br /> Nube de Dagas
<br /> Llama Continua
<br /> Corona de Locura
<br /> Oscuridad
<br /> Visión en la Oscuridad
<br /> Aliento de Dragón
<br /> Fascinar
<br /> Hallar Corcel
<br /> Hoja de Fuego
<br /> Calentar Metal
<br /> Inmovilizar Persona
<br /> Invisibilidad
<br /> Abrir
<br /> Levitar
<br /> Localizar Objeto
<br /> Flecha Ácida de Melf
<br /> Espina Mental ^X^
<br /> Paso Brumoso

\columnbreak

<br /> Fuerza Fantasmagórica
<br /> Pirotecnia ^X^
<br /> Rayo de Debilitamiento
<br /> Rayo Abrasador
<br /> Hoja Sombría ^X^
<br /> Trepar por Paredes
<br /> Sugerencia
<br /> Latigazo Mental de Tasha ^T^
<br /> Telaraña

##### 3.º Nivel
Conceder Maldición
<br /> Clarividencia
<br /> Contraconjuro
<br /> Disipar Magia
<br /> Arma Elemental
<br /> Enemigos Abundan ^XGE^
<br /> Miedo
<br /> Vuelo
<br /> Forma Gaseosa
<br /> Acelerar
<br /> Hambre de Hadar
<br /> Patrón Hipnótico
<br /> Transferencia de Vida ^XGE^
<br /> Imagen Mayor
<br /> Meteoritos de Melf
<br /> Corcel Fantasma
<br /> Protección contra la Energía
<br /> Quitar Maldición
<br /> Envío
<br /> Hablar con los Muertos
<br /> Invocar Demonios Menores ^X^
<br /> Invocar Engendro de Sombra ^T^
<br /> Invocar No Muertos ^T^
<br /> Sirviente Menor ^X^
<br /> Lenguas
<br /> Toque Vampírico
<br /> Respirar Bajo el Agua
<br /> Caminar Sobre el Agua

##### 4.º Nivel
Ojo Arcano
<br /> Destierro
<br /> Marchitar
<br /> Encantar Monstruo ^X^
<br /> Compulsión
<br /> Palabra de Muerte
<br /> Tentáculos Negros de Evard
<br /> Hallar Corcel Mayor ^X^
<br /> ✦ Fuego y Azufre
<br /> Invisibilidad Mayor
<br /> Terreno Alucinatorio
<br /> Cofre Secreto de Leomund
<br /> Localizar Criatura
<br /> Sabueso Fiel de Mordenkainen
<br /> Esfera Resiliente de Otiluke
<br /> Asesino Fantasmagórico
<br /> Sombra de Moil ^X^
<br /> Resplandor Enfermizo ^X^

\columnbreak

<div style='margin-top:-10px;'></div>

<br /> Invocar Aberración ^T^
<br /> Invocar Demonio Mayor ^X^
<br /> Esfera Vitriólica ^X^

##### 5.º Nivel
Concha Antivida
<br /> Danza Macabra ^XGE^
<br /> Disipar el Bien y el Mal
<br /> Dominar Persona
<br /> Enervación ^XGE^
<br /> Paso Lejano ^XGE^
<br /> Geas
<br /> Inmovilizar Monstruo
<br /> Inmolación ^XGE^
<br /> Plaga de Insectos
<br /> Modificar Memoria
<br /> Inundación de Energía Negativa ^XGE^
<br /> ✦ Lluvia de Fuego
<br /> Vínculo Telepático de Rary
<br /> ✦ Ritual de Invocación
<br /> Escrutar
<br /> Estática Sináptica ^XGE^
<br /> Círculo de Teletransportación
<br /> Muro de Fuerza

##### 6.º Nivel
Puerta Arcana
<br /> Círculo de Muerte
<br /> Contingencia
<br /> Crear No Muertos
<br /> Desintegrar
<br /> Invocación Instantánea de Drawmij
<br /> Mordedura de Ojo
<br /> Esfera de Invulnerabilidad
<br /> Dañar
<br /> Investidura de Llama ^X^
<br /> Tarro Mágico
<br /> Sugerencia Masiva
<br /> Prisión Mental ^X^
<br /> Danza Irresistible de Otto
<br /> Aliado Planar
<br /> Dispersión ^X^
<br /> ✦ Furia Sombría
<br /> Jaula del Alma ^X^
<br /> Invocar Demonio ^T^
<br /> Visión Verdadera
<br /> Palabra de Recuerdo


\columnbreak


##### 7.º Nivel
Bola de Fuego Retardada
<br /> Eterealidad
<br /> Toque de la Muerte
<br /> Tormenta de Fuego
<br /> Jaula de Fuerza
<br /> Espada de Mordenkainen
<br /> Secuestrar
<br /> Teletransporte

##### 8º Nivel
Marchitamiento<br />&nbsp;&nbsp;Horrible de Abi-Dalzim ^XGE^
<br /> Campo Antimágico
<br /> ✦ Cataclismo
<br /> Clon
<br /> Semiplano
<br /> Dominar Monstruo
<br /> Mente Débil
<br /> Facilidad de Palabra
<br /> Oscuridad Loca ^XGE^
<br /> Ruptura de la Realidad ^EGW^
<br /> Telepatía

##### 9º Nivel
Hoja del Desastre ^TCE^
<br /> Portal
<br /> Prisión
<br /> Lluvia de Meteoros
<br /> Grito Psíquico ^XGE^
<br /> Vacío Voraz ^EGW^
<br /> Raro

</div>

<div style='margin-top:-10px;'></div>

> ##### Regla Variante: Corcel de Xoroth
> Las criaturas invocadas por un brujo con los conjuros *hallar corcel* y *hallar corcel mayor* sean demonios en lugar de los otros tipos de criaturas listados en esos conjuros. Además, el conjuro *hallar corcel mayor* puede invocar un corcel vil además de las otras criaturas listadas.

<div class='footnote'>PARTE 2 | MAGIA</div>

</div>





\pagebreakNum

## Descripciones de Conjuros

#### Cataclismo
*Conjuración de nivel 8*
___
- **Tiempo de Lanzamiento:** 1 acción
- **Alcance:** 150 pies
- **Componentes:** V, S, M (un trozo de carbón)
- **Duración:** Instantánea
___
Haces que el suelo se agriete y se parta, escupiendo magma y fuego en un radio de 60 pies centrado en un punto dentro del alcance. Cada criatura en el área debe hacer una tirada de salvación de Destreza o recibir 10d6 de daño por fuego, la mitad del daño si tiene éxito.

Una criatura que reciba daño por fuego de este conjuro queda envuelta en llamas, recibiendo 2d6 de daño por fuego al inicio de cada uno de sus turnos. Ella u otra criatura adyacente pueden usar su acción para apagar las llamas, recibiendo 1d4 de daño por fuego en el proceso.

El suelo en el área de este conjuro queda dañado, convirtiéndose en terreno difícil. Permanece caliente durante 1 minuto, y cualquier criatura que entre en el área por primera vez en su turno o que comience su turno allí recibe 1d4 de daño por fuego.

#### Vacío Oscuro
*Evocación de nivel 1*
___
- **Tiempo de Lanzamiento:** 1 acción
- **Alcance:** 30 pies
- **Componentes:** V, S, M (un símbolo sagrado)
- **Duración:** Instantánea
___
Manipulas la tela de la realidad alrededor de un objetivo dentro del alcance, extrayendo energías nigrománticas de él y de criaturas de tu elección a 5 pies del mismo. El objetivo debe hacer una tirada de salvación de Constitución, recibiendo 2d4 de daño necrótico si falla, o la mitad del daño si tiene éxito.

***A niveles superiores.*** Cuando lanzas este conjuro usando una ranura de nivel 2 o superior, el daño aumenta en 1d4 por cada nivel de ranura por encima del 1.º.

#### Piel Demoníaca
*Transmutación de nivel 1*
___
- **Tiempo de Lanzamiento:** 1 acción
- **Alcance:** Personal
- **Componentes:** V, S, M (piel seca de un demonio o engendro)
- **Duración:** 8 horas
___
Tu piel se cubre con una capa de energía vil, infundiéndote con vigor demoníaco. Tu Clase de Armadura mínima se vuelve 8 + tu modificador de lanzamiento de conjuros. Tu CA no puede bajar de 10 de esta manera. Además, tu total de puntos de golpe actuales y máximos aumenta en 1.

***A niveles superiores.*** Cuando lanzas este conjuro usando una ranura de nivel 2 o superior, tu CA mínima y tu total de puntos de golpe actuales y máximos aumentan en 1 por cada nivel de ranura por encima del 1.º.

\columnbreak

#### Diabolismo
*Truco de Nigromancia*
___
- **Tiempo de Lanzamiento:** 1 acción
- **Alcance:** Personal
- **Componentes:** S
- **Duración:** Hasta 1 hora
___
Este conjuro canaliza una pequeña cantidad de energía oscura. Creas uno de los siguientes efectos mágicos dentro del alcance:
- Elige un punto dentro de 30 pies. En un radio de 5 pies de ese punto, la luz brillante se convierte en luz tenue, y la luz tenue se convierte en oscuridad durante 1 hora. Cualquier fuente de luz dentro del área tiene la luz que produce suprimida durante la duración.
- Un objeto de hasta 1 pie cúbico de tamaño o un área de hasta 1 pie cuadrado que toques se descompone ligeramente. La madera se pudre, el vidrio se agrieta, las flores se marchitan. Si sigues tocando el objetivo, el deterioro avanza; después de 1 minuto, el objetivo es destruido. Este conjuro no afecta a criaturas, objetos mágicos o materiales resistentes como metal y piedra.
- Puedes reanimar a una bestia Pequeña de 0 CR durante 1 hora. Es no-muerta y obedece tus órdenes lo mejor que pueda, aunque no puede atacar. No puedes usar este efecto nuevamente hasta que la criatura reanimada muera o el efecto termine.
- Prendes fuego instantáneamente a una vela, antorcha o pequeña hoguera. El fuego brilla en rojo tenue, verde brillante o púrpura sombrío a tu elección hasta que se apague.
- La yema de tu dedo brilla verde o púrpura durante hasta 1 minuto. Mientras brilla, puedes usar tu dedo para dibujar líneas luminosas del mismo color en una superficie sólida que duran 1 hora.

Si lanzas este conjuro múltiples veces, puedes tener hasta tres de sus efectos no instantáneos activos a la vez, y puedes disipar uno de estos efectos como una acción.

<div class='footnote'>PARTE 2 | MAGIA</div>

\pagebreakNum

#### Drenar Vida
*Nigromancia de nivel 1*
___
- **Tiempo de Lanzamiento:** 1 acción
- **Alcance:** 30 pies
- **Componentes:** V, S
- **Duración:** Concentración, hasta 1 minuto
___
Provocas que un rayo verde de energía salga de los ojos y boca de la criatura objetivo y se dirija hacia tu mano, formando un flujo continuo de energía que los une.

Haz un ataque de conjuro a distancia contra esa criatura. Si impactas, el objetivo recibe 1d8 de daño necrótico, y en cada uno de tus turnos durante la duración, puedes usar tu acción para infligir 1d8 de daño necrótico automáticamente. Cada vez que el objetivo recibe daño de este conjuro, ganas un número de puntos de golpe igual a la mitad del daño infligido y su total de puntos de golpe máximo se reduce en la misma cantidad. Esta reducción dura hasta que termine un descanso prolongado.

El conjuro termina si usas tu acción para hacer otra cosa. También termina si el objetivo se encuentra fuera del alcance del conjuro o si tiene cobertura total de ti. Este conjuro no tiene efecto sobre criaturas que sean constructos o no muertos.

***A niveles superiores.*** Cuando lanzas este conjuro usando una ranura de nivel 2 o superior, el daño inicial aumenta en 1d8 por cada nivel de ranura por encima del 1.º.

#### Llama Vil
*Truco de Evocación*
___
- **Tiempo de Lanzamiento:** 1 acción
- **Alcance:** 60 pies
- **Componentes:** V, S
- **Duración:** Instantánea
___
Una llama verde avanza sobre el suelo hacia una criatura dentro del alcance. Haz un ataque de conjuro a distancia contra el objetivo. Si impactas, el objetivo recibe 1d8 de daño por fuego. La llama vil ignora la resistencia al fuego, y las criaturas inmunes al daño por fuego se consideran resistentes.

El daño de este conjuro aumenta en 1d8 cuando alcanzas el nivel 5 (2d8), nivel 11 (3d8) y nivel 17 (4d8).

#### Fuego y Azufre
*Evocación de nivel 4*
___
- **Tiempo de Lanzamiento:** 1 acción
- **Alcance:** 60 pies
- **Componentes:** V, S
- **Duración:** Instantánea
___
Formas seis orbes de fuego sobre tu cabeza, que lanzas hacia objetivos dentro de 20 pies de un punto que elijas dentro del alcance. Puedes dirigir los orbes para que golpeen a un objetivo o a varios. Un objetivo recibe 1d10 de daño por fuego por cada orbe que lo impacte y puede intentar una tirada de salvación de Destreza para recibir la mitad del daño. Cada objetivo realiza solo una tirada de salvación, independientemente de cuántos orbes lo impacten.

***A niveles superiores.*** Cuando lanzas este conjuro usando una ranura de nivel 5 o superior, el conjuro crea un orbe adicional por cada nivel de ranura por encima del 4.º.

\columnbreak

#### Desgarrar la Mente
*Encantamiento de nivel 2*
___
- **Tiempo de Lanzamiento:** 1 acción
- **Alcance:** 120 pies
- **Componentes:** V
- **Duración:** Concentración, hasta 1 minuto
___
Envuelves la mente de una criatura que puedes ver dentro del alcance. El objetivo debe realizar una tirada de salvación de Sabiduría. Si falla, recibe 2d6 de daño psíquico y tiene desventaja en todas las tiradas de ataque y chequeos de habilidad durante la duración del conjuro. Si tiene éxito, el objetivo recibe la mitad del daño, pero no sufre otros efectos.

Al final de cada uno de sus turnos, el objetivo puede realizar otra tirada de salvación de Sabiduría, terminando el conjuro si tiene éxito.

***A niveles superiores.*** Cuando lanzas este conjuro usando una ranura de nivel 3 o superior, el daño aumenta en 1d6 por cada nivel de ranura por encima del 2.º.

#### Lluvia de Fuego
*Evocación de nivel 5*
___
- **Tiempo de Lanzamiento:** 1 acción
- **Alcance:** 120 pies
- **Componentes:** V, S
- **Duración:** Concentración, hasta 1 minuto
___
Invocas una nube en un punto dentro del alcance, causando que gotas llameantes cubran un área de 15 pies de radio a su alrededor. Cada criatura que entre en el área por primera vez en su turno o que comience su turno allí debe realizar una tirada de salvación de Destreza, recibiendo 3d12 de daño por fuego si falla, o la mitad si tiene éxito.

Como acción adicional, puedes mover la nube hasta 15 pies a un punto que puedas ver. Los objetos inflamables que no estén siendo llevados o usados en el área se encienden.

***A niveles superiores.*** Cuando lanzas este conjuro usando una ranura de nivel 6 o superior, inflige un daño adicional de 1d12 por cada nivel de ranura por encima del 5.º.

<div class='footnote'>PARTE 2 | MAGIA</div>

\pagebreakNum

#### Ritual de Invocación
*Conjuración de nivel 5 (ritual)*
___
- **Tiempo de Lanzamiento:** 10 minutos
- **Alcance:** 10 pies
- **Componentes:** V, S, M (un zafiro de sangre con valor de 100 po)
- **Duración:** 1 hora
___
Invocas un portal de invocación en un espacio vacío dentro del alcance. Aparece como una estatua sombría de una figura con capucha, sosteniendo su capa abierta para revelar un remolino hacia el vacío abisal.

Usando 1 minuto, puedes canalizar energía hacia la estatua y pronunciar el nombre verdadero de una criatura. Si la criatura está en tu plano de existencia, un espejo resplandeciente aparece frente a ella que solo ella puede ver, a través del cual puede percibirte a ti y a tu entorno, pero tú no puedes verla.

La criatura puede ignorar el espejo, en cuyo caso desaparece después de 1 minuto y un nuevo espejo no puede aparecer frente a esa criatura durante 24 horas, o atravesarlo, siendo teletransportada al espacio frente a la piedra de invocación.

El ritual de invocación solo puede llamar a criaturas hacia él, una criatura no puede usar la piedra de invocación para regresar a su ubicación anterior.

#### Rayo de Sombra
*Truco de Nigromancia*
___
- **Tiempo de Lanzamiento:** 1 acción
- **Alcance:** 120 pies
- **Componentes:** V, S
- **Duración:** Instantánea
___
Disparas una ráfaga de energía necrótica hacia una criatura dentro del alcance. Haz un ataque de conjuro a distancia contra el objetivo. Si impactas, el objetivo recibe 1d8 de daño necrótico.

Cuando el conjuro impacta, puedes optar por recibir 1 punto de daño psíquico para aumentar el daño infligido a 1d12 de daño necrótico.

El daño infligido por el conjuro aumenta en un dado cuando alcanzas el nivel 5 (2d8 o 2d12), nivel 11 (3d8 o 3d12) y nivel 17 (4d8 o 4d12). El daño opcional recibido aumenta en 2 cuando alcanzas el nivel 5 (3), nivel 11 (5) y nivel 17 (7).

#### Furia Sombría
*Encantamiento de nivel 6*
___
- **Tiempo de Lanzamiento:** 1 acción
- **Alcance:** 60 pies
- **Componentes:** V, S
- **Duración:** Concentración, hasta 1 minuto
___
Extiendes tu brazo y canalizas energía de las sombras sobre criaturas dentro de un radio de 10 pies de un punto dentro del alcance. Cada criatura recibe 5d8 de daño psíquico y debe realizar una tirada de salvación de Sabiduría o quedar aturdida durante la duración del conjuro.

Una criatura aturdida debe realizar una tirada de salvación de Constitución al final de cada uno de sus turnos. Si tiene éxito, el efecto de aturdimiento termina.

<div class='footnote'>PARTE 2 | MAGIA</div>

\pagebreakNum

# Apéndice C: Compañeros Demoníacos
## Parte I: Esbirros
___
___
> ## Guardia Vil
>*Diablillo mediano (demonio), maligno legal*
> ___
> - **CA** 14 (armadura natural)
> - **PG** Tu Mod. Inteligencia + Mod. Constitución de criatura + 5 veces tu nivel de brujo
> - **Velocidad** 30 pies 
>___
>|FUE|DES|CON|INT|SAB|CAR|
>|:---:|:---:|:---:|:---:|:---:|:---:|
>|16 (+3)|12 (+1)|14 (+2)|10 (+0)|12 (+1)|12 (+1)|
>___
> - **Tiradas de Salvación** Fue +5, Con +4
> - **Habilidades** Atletismo +5, Intimidación +3, Percepción +3
> - **Resistencia al Daño** Contundente, perforante y cortante de armas no mágicas  
> - **Sentidos** Visión en la oscuridad 60 pies, Percepción pasiva 11
> - **Idiomas** Eredun, comprende los idiomas de su invocador
> ___
>
> ***Poder del Maestro.*** Los siguientes números aumentan en 1 cuando tu bonificación de competencia aumenta en 1: CA, las bonificaciones de habilidades y el bono a sus tiradas de ataque y daño.
>
> ***Golpe de Legión.*** Una vez por turno, cuando el guardia vil realiza un ataque con Hacha de Legión, puede realizar otro ataque contra una criatura diferente que esté a 5 pies tanto del primer objetivo como del guardia vil.
>
> ### Acciones
>
> ***Hacha de Legión.*** *Ataque de Arma Cuerpo a Cuerpo:* +5 para golpear, alcance 5 pies, un objetivo. *Impacto:* 1d10 + 3 de daño cortante.
> 
> ### Reacciones
> ***Persecución.*** Cuando una criatura deja de moverse tras salir del alcance del guardia vil, el guardia vil puede usar su reacción para moverse hasta su velocidad hacia la criatura. Este movimiento no provoca ataques de oportunidad. El guardia vil puede luego realizar un ataque con Hacha de Legión contra la criatura si está a su alcance.
>
> \columnbreak
>
> #### Núcleo Demoníaco
> El núcleo demoníaco de un guardia vil es un corazón que nunca parece dejar de gotear sangre. Un brujo que lo lleve consigo obtiene los siguientes beneficios:
>
> **Nivel 2:** Mientras lleve un núcleo de guardia vil, el brujo tiene ventaja en chequeos de Fuerza (Atletismo) y Sabiduría (Supervivencia). Mientras sostenga el núcleo, puede lanzar el conjuro *armadura de mago* a voluntad.
>
> **Nivel 5:** Mientras sostenga el núcleo, el brujo conoce el conjuro *arma mágica* y puede lanzarlo sin gastar una ranura de conjuro una vez por descanso largo.
>
> **Nivel 9:** Mientras sostenga el núcleo, el brujo conoce el conjuro *✦ furia de sangre y heroísmo* y puede lanzarlo sin gastar una ranura de conjuro una vez por descanso largo.
> 
> #### Evolución de Supremacía
> Un guardia vil al servicio de un demonólogo evoluciona a un señor vil al nivel 14. Su piel se vuelve gris y aumenta de tamaño, empuñando un hacha masivamente grande. Gana los siguientes beneficios:
> - Su tamaño aumenta a Grande, lo que hace que su ataque con Hacha de Legión cause un dado adicional de daño y tenga un alcance de 10 pies.
> - Como acción, puede golpear el suelo con su arma, causando que se sacuda. Trata esto como si lanzara el conjuro *temblor de tierra ^XGE^* como un conjuro de nivel 2 usando tu CD de salvación de conjuro de brujo.
> - Como acción, puede realizar una tirada de ataque única contra cualquier número de criaturas dentro de 10 pies. Lanza daño de un ataque con Hacha de Legión para cada criatura a la que la tirada de ataque impacte.

<img src='https://www.gmbinder.com/images/DCctq70.jpg' style='position:absolute; bottom:-230px; right:0px; width:800px' />
<img src='https://www.gmbinder.com/images/3e9S91s.png' style='position:absolute; top:-175px; right:0px; width:900px' />
<img src='https://www.gmbinder.com/images/nZZkz5p.png' style='position:absolute; top:0px; right: -60px; width: 900px; transform:scaleY(-1);' />

<div class='footnote footnote-white'>APÉNDICE C | COMPAÑEROS DEMONÍACOS</div>

\pagebreakNum
___
___
> ## Manáfago
>*Diablillo mediano (demonio), maligno neutral*
> ___
> - **Clase de Armadura** 13 (armadura natural)
> - **Puntos de Golpe** Tu Mod. Inteligencia + Mod. Constitución de criatura + 5 por tu nivel de brujo
> - **Velocidad** 40 pies 
>___
>|FUE|DES|CON|INT|SAB|CAR|
>|:---:|:---:|:---:|:---:|:---:|:---:|
>|17 (+3)|12 (+1)|14 (+2)|6 (-3)|13 (+1)|14 (+2)|
>___ 
> - **Tiradas de Salvación** Des +3 , Con +4 
> - **Habilidades** Percepción +3, Sigilo +3, Supervivencia +3
> - **Sentidos** Visión ciega 60 pies, Percepción pasiva 13
> - **Idiomas** Entiende Eredun y los idiomas de su invocador, pero no puede hablar
> ___
>
> ***Poder del Maestro.*** Los siguientes números aumentan en 1 cuando tu bonificación de competencia aumenta en 1: CA, las bonificaciones de habilidades y el bono a sus tiradas de ataque y daño.
>
> ***Disrupción Mágica.*** Si el cazador vil inflige daño a una criatura que luego deba hacer una tirada de salvación de Constitución para mantener la concentración en un conjuro, esa tirada se realiza con desventaja.
>
> ***Resistencia Mágica.*** El cazador vil tiene ventaja en las tiradas de salvación contra conjuros y otros efectos mágicos.
>
> ***Detección Mágica.*** El cazador vil puede percibir la magia dentro de un radio de 60 pies a voluntad. Este rasgo funciona como el conjuro *detectar magia*, pero no es mágico en sí mismo.
>
> ### Acciones
>
> ***Mordisco Sombrío.*** *Ataque de Arma Cuerpo a Cuerpo:* +5 para golpear, alcance 5 pies, un objetivo. *Impacto:* 1d6 + 3 de daño necrótico
>
> ***Desgarrar.*** *Ataque de Arma Cuerpo a Cuerpo:* +5 para golpear, alcance 5 pies, un objetivo. *Impacto:* 1d8 + 3 de daño perforante 
>
> \columnbreak
>
> #### Núcleo Demoníaco
> El núcleo demoníaco de un cazador vil es un tentáculo retorcido. Un brujo que lo lleve consigo obtiene los siguientes beneficios:
>
> **Nivel 2:** Mientras lleve un núcleo de cazador vil, el brujo tiene ventaja en chequeos de Inteligencia (Investigación) y Sabiduría (Percepción). Mientras sostenga el núcleo, puede lanzar el conjuro *detectar magia* a voluntad.
>
> **Nivel 5:** Mientras sostenga el núcleo, el brujo conoce el conjuro *Contrahechizo* y puede lanzarlo sin gastar una ranura de conjuro una vez por descanso largo.
>
> **Nivel 9:** Mientras sostenga el núcleo, el brujo conoce el conjuro *localizar criatura* y puede lanzarlo sin gastar una ranura de conjuro una vez por descanso largo.
> 
> #### Evolución de Supremacía
> Un cazador vil al servicio de un demonólogo evoluciona a un acechador vil al nivel 14. Su piel se vuelve roja y su silueta parece parpadear dentro y fuera de la realidad. Gana los siguientes beneficios:
> - Puede usar la acción de Correr como una acción adicional.
> - Cuando supera una tirada de salvación contra un conjuro, recupera puntos de golpe igual al doble del nivel del conjuro.
> - Su cuerpo se desplaza dentro y fuera de la realidad, causando que las tiradas de ataque contra él tengan desventaja. Si es impactado por un ataque, este rasgo se interrumpe hasta el final de su próximo turno. Este rasgo también se interrumpe si el cazador vil está incapacitado o tiene una velocidad de 0.

<img src='https://www.gmbinder.com/images/moaDsD1.jpg' style='position:absolute; bottom:-80px; left:0px; width:800px;' />
<img src='https://www.gmbinder.com/images/bNHsRrG.png' style='position:absolute; bottom:-10px; left:0px; width:900px; transform:scaleX(-1);' />
<img src='https://www.gmbinder.com/images/nZZkz5p.png' style='position:absolute; top:0px; right: -60px; width: 900px; transform:scaleY(-1); ' />

<div class='footnote footnote-white'>APÉNDICE C | COMPAÑEROS DEMONÍACOS</div>

\pagebreakNum
___
___
> ## Diablillo
>*Pequeño ser infernal (demonio), caótico maligno*
> ___
> - **Clase de Armadura** 13
> - **Puntos de Golpe** tu modificador de Inteligencia más el modificador de Constitución del diablillo más cinco veces tu nivel de brujo
> - **Velocidad** 25 pies 
>___
>|FUE|DES|CON|INT|SAB|CAR|
>|:---:|:---:|:---:|:---:|:---:|:---:|
>|6 (-2)|16 (+3)|13 (+1)|16 (+3) |8 (-1)|14 (+2)|
>___
> - **Tiradas de Salvación** Des +5, Sab +1
> - **Habilidades** Engaño +4, Juego de Manos +5, Sigilo +5
> - **Sentidos** visión en la oscuridad 60 pies, Percepción pasiva 11
> - **Idiomas** Eredun, comprende los idiomas de su invocador 
> ___
>
> ***Poder del Maestro.*** Los siguientes números aumentan en 1 cuando tu bonificación de competencia aumenta en 1: CA, las bonificaciones de habilidades y el bono a sus tiradas de ataque y daño.
>
> ### Acciones
>
> ***Garra.*** *Ataque de Arma Cuerpo a Cuerpo:* +5 para golpear, alcance 5 pies, un objetivo. *Impacto:* 1d4 + 3 de daño cortante.
>
> ***Rayo de Fuego.*** *Ataque de Conjuro a Distancia:* +4 para golpear, alcance 60 pies, un objetivo. *Impacto:* 1d8 + 3 de daño por fuego.
> 
> ### Reacciones
> ***Cambio de Fase.*** Cuando el diablillo sea objeto de un efecto que le permita hacer una tirada de salvación para recibir la mitad del daño, puede usar su reacción para cambiar de fase con el mundo y tener éxito automáticamente.
>
> \columnbreak
>
> #### Núcleo Demoníaco
> El núcleo demoníaco de un diablillo parece un fragmento roto de cuerno, caliente al tacto. Un brujo que lleva consigo el núcleo demoníaco de un diablillo obtiene los siguientes beneficios:
> 
> **Nivel 2:** Mientras lleva un núcleo de diablillo, el brujo tiene ventaja en chequeos de Destreza (Juego de Manos) y Destreza (Sigilo). Mientras sostiene el núcleo, puede lanzar el truco *mofa vil*.
> 
> **Nivel 5:** Mientras sostiene el núcleo, el brujo conoce el conjuro *parpadeo* y puede lanzarlo sin gastar una ranura de conjuro de brujo una vez por descanso largo.
>
> **Nivel 9:** Mientras sostiene el núcleo, el brujo conoce el conjuro *✦ lluvia de fuego* y puede lanzarlo sin gastar una ranura de conjuro de brujo una vez por descanso largo.
>
> #### Evolución de Supremacía
> Un diablillo al servicio de un demonólogo evoluciona a un diablillo vil al nivel 14. El diablillo aumenta de tamaño, ganando enormes cuernos y un par de alas. Gana los siguientes beneficios:
> - Tiene una velocidad de vuelo de 25 pies.
> - Cuando realiza un ataque con Rayo de Fuego, ataca tres veces.
> - Hasta tres veces al día, un objetivo golpeado por su Rayo de Fuego es afectado por *disipar magia*.

<img src='https://www.gmbinder.com/images/z08oeTn.jpg' style='position:absolute; bottom:-100px; left:0px; width:800px' />
<img src='https://www.gmbinder.com/images/bNHsRrG.png' style='position:absolute; bottom:60px; left:0px; width:900px; transform:scaleX(-1.5);' />
<img src='https://www.gmbinder.com/images/nZZkz5p.png' style='position:absolute; top:0px; right: -60px; width: 900px; transform:scaleY(-1);' />

<div class='footnote footnote-white'>APÉNDICE C | COMPAÑEROS DEMONÍACOS</div>


\pagebreakNum
___
___
> ## Súcubo
>*Ser infernal mediano (demonio), caótico maligno*
> ___
> - **Clase de Armadura** 13
> - **Puntos de Golpe** tu modificador de Inteligencia más el modificador de Constitución del súcubo más cinco veces tu nivel de brujo
> - **Velocidad** 30 pies, volar 15 pies
>___
>|FUE|DES|CON|INT|SAB|CAR|
>|:---:|:---:|:---:|:---:|:---:|:---:|
>|8 (-1)|16 (+3)|13 (+1)|10 (+0)|12 (+1)|16 (+3)|
>___
> - **Tiradas de Salvación** Car +5, Sab +3 
> - **Habilidades** Engaño +5, Persuasión +5, Sigilo +5
> - **Sentidos** visión en la oscuridad 60 pies, Percepción pasiva 11
> - **Idiomas** Eredun, Común, entiende los idiomas de su invocador
> ___
>
> ***Poder del Maestro.*** Los siguientes números aumentan en 1 cuando tu bonificación de competencia aumenta en 1: CA, las bonificaciones de habilidades y el bono a sus tiradas de ataque y daño.
>
> ***Cambiaformas.*** El súcubo puede usar su acción para transformarse en un humanoide Pequeño o Mediano, o volver a su forma verdadera. Aparte de su tamaño y velocidad, sus estadísticas son las mismas en cada forma. Cualquier equipo que lleve puesto o cargue no se transforma. Regresa a su forma verdadera si muere.
>
> ***Maestra del Látigo.*** Cuando el súcubo golpea a una criatura con su Látigo del Dolor, el objetivo puede ser movido hasta 10 pies hacia o alejado del súcubo.
>
> ### Acciones
>
> ***Látigo del Dolor.*** *Ataque de Arma Cuerpo a Cuerpo:* +5 para golpear, alcance 10 pies, un objetivo. *Impacto:* 1d6 + 3 de daño necrótico, y una criatura debe superar una tirada de salvación de Constitución contra la CD de conjuro de su maestro, o su velocidad de movimiento se reduce en 10 pies hasta el inicio del siguiente turno del súcubo.
>
> ***Invisibilidad.*** El súcubo se vuelve invisible mágicamente hasta que ataque, o hasta que su concentración termine (como si estuviera concentrándose en un conjuro). Cualquier equipo que lleve puesto o cargue también se vuelve invisible.
>
> \columnbreak
> 
> #### Núcleo Demoníaco
> El núcleo demoníaco de un súcubo parece... ¿un tubo de lápiz labial? Un brujo que lleva el núcleo demoníaco de un súcubo obtiene los siguientes beneficios:
> 
> **Nivel 2:** Mientras lleva el núcleo de un súcubo, el brujo tiene ventaja en chequeos de Carisma (Engaño) y Carisma (Persuasión). Mientras sostiene el núcleo, puede lanzar el conjuro *Encantar persona* a voluntad.
> 
> **Nivel 5:** Mientras sostiene el núcleo, el brujo conoce el conjuro *sugerencia* y puede lanzarlo sin gastar una ranura de conjuro de brujo una vez por descanso largo.
>
> **Nivel 9:** Mientras sostiene el núcleo, el brujo conoce el conjuro *dominar persona* y puede lanzarlo sin gastar una ranura de conjuro de brujo una vez por descanso largo.
>
> #### Evolución de Supremacía
> Un súcubo al servicio de un demonólogo evoluciona a un súcubo vil al nivel 14. La piel del súcubo se vuelve roja, sus cuernos se hacen más pronunciados y sus ojos adquieren un brillo verde. Gana los siguientes beneficios:
> - Cuando realiza un ataque con Látigo del Dolor, puede golpear hasta dos objetivos.
> - El alcance de su Látigo del Dolor aumenta a 20 pies.
> - Como acción, puede seducir a un humanoide en un radio de 60 pies. Si el objetivo falla su tirada de salvación de Carisma contra la CD de tus conjuros, queda incapacitado durante 1 minuto. Puede repetir su tirada al inicio de su turno o cuando reciba daño, terminando el efecto al tener éxito. Mientras una criatura esté seducida, el súcubo no puede seducir a otra criatura.

<img src='https://www.gmbinder.com/images/lc9zJNs.jpg' style='position:absolute; bottom:-280px; left:00px; width:800px' />
<img src='https://www.gmbinder.com/images/3e9S91s.png' style='position:absolute; top:-130px; left:0px; width:800px' />
<img src='https://www.gmbinder.com/images/bNHsRrG.png' style='position:absolute; bottom:-75px; left:0px; width:900px; transform:scaleX(-1);' />
<img src='https://www.gmbinder.com/images/nZZkz5p.png' style='position:absolute; top:0px; right: -60px; width: 900px; transform:scaleY(-1);' />

<div class='footnote footnote-white'>APÉNDICE C | COMPAÑEROS DEMONÍACOS</div>


\pagebreak
___
___
> ## Abisario
>*Ser infernal mediano (demonio), neutral maligno*
> ___
> - **Clase de Armadura** 16 (armadura natural)
> - **Puntos de Golpe** tu modificador de Inteligencia más el modificador de Constitución del caminante del vacío más cinco veces tu nivel de brujo
> - **Velocidad** 30 pies
>___
>|FUE|DES|CON|INT|SAB|CAR|
>|:---:|:---:|:---:|:---:|:---:|:---:|
>|16 (+3)|8 (-1)|16 (+3)|8 (-1)|14 (+2)|10 (+0)|
>___
> - **Tiradas de Salvación** Des +1, Sab +4
> - **Habilidades** Atletismo +5, Intimidación +2, Percepción +4
> - **Vulnerabilidades al Daño** radiante 
> - **Resistencias al Daño** daño contundente, perforante y cortante de armas no mágicas
> - **Inmunidad a Condiciones** agotado, apresado
> - **Sentidos** visión en la oscuridad 60 pies, Percepción pasiva 14
> - **Idiomas** Eredun, comprende los idiomas de su invocador
> ___
>
> ***Poder del Maestro.*** Los siguientes números aumentan en 1 cuando tu bonificación de competencia aumenta en 1: CA, bonificaciones de habilidades y el bono a sus tiradas de ataque y daño.
>
> ***Presencia Amenazante.*** Cualquier criatura dañada por el caminante del vacío tiene desventaja en cualquier tirada de ataque que haga contra un objetivo que no sea el caminante del vacío, hasta el final del siguiente turno del caminante del vacío.
>
> ### Acciones
>
>  ***Golpe.*** *Ataque de Arma Cuerpo a Cuerpo:* +5 para golpear, alcance 10 pies, un objetivo. *Impacto:* 1d6 + 3 de daño contundente.
>
> ***Sufrimiento.*** *Ataque de Arma Cuerpo a Cuerpo:* +5 para golpear, alcance 10 pies, un objetivo. *Impacto:* 1d6 + 3 de daño necrótico.
>
> ***Muralla de Sombras (1/día).*** El caminante del vacío gana un número de puntos de golpe temporales igual a su nivel de maestro.
>
> \columnbreak
> 
> #### Núcleo Demoníaco
> El núcleo demoníaco de un caminante del vacío parece un orbe de pura sombra. Un brujo que lleva el núcleo demoníaco de un caminante del vacío obtiene los siguientes beneficios:
> 
> **Nivel 2:** Mientras lleva un núcleo de caminante del vacío, el brujo tiene ventaja en chequeos de Sabiduría (Perspicacia) y Carisma (Intimidación). Mientras sostiene el núcleo, puede lanzar el conjuro *armadura de Agathys* a voluntad.
> 
> **Nivel 5:** Mientras sostiene el núcleo, el brujo conoce el conjuro *hambre de Hadar* y puede lanzarlo sin gastar una ranura de conjuro de brujo una vez por descanso largo.
>
> **Nivel 9:** Mientras sostiene el núcleo, el brujo conoce el conjuro *desgaste ^XGE^* y puede lanzarlo sin gastar una ranura de conjuro de brujo una vez por descanso largo.
>
> #### Evolución de Supremacía
> Un caminante del vacío al servicio de un demonólogo evoluciona a un señor del vacío al nivel 14. El cuerpo del caminante del vacío se vuelve más oscuro, adquiere un brillo azul y brota una armadura negra. Gana los siguientes beneficios:
> - Gana un bono de +1 a la clase de armadura.
> - Las criaturas que golpeen al caminante del vacío con un ataque cuerpo a cuerpo reciben 5 (1d10) de daño necrótico.
> - Como acción, el caminante del vacío puede infundir miedo del vacío en cada criatura de tu elección que esté a 60 pies de él y sea consciente de su presencia. Las criaturas deben superar una tirada de salvación de Sabiduría contra la CD de tus conjuros o quedar asustadas durante 1 minuto. Una criatura puede repetir la tirada de salvación al final de cada uno de sus turnos, terminando el efecto sobre sí misma con éxito. Si una criatura supera su tirada de salvación o el efecto termina para ella, es inmune al efecto de miedo del caminante del vacío durante las próximas 24 horas.

<img src='https://www.gmbinder.com/images/dPcFWbx.jpg' style='position:absolute; bottom:-160px; left:0px; width:800px' />
<img src='https://www.gmbinder.com/images/L60ii4e.png' style='position:absolute; top:50px; left:0px; width:800px' />
<img src='https://www.gmbinder.com/images/nZZkz5p.png' style='position:absolute; top:0px; right: -60px; width: 900px; transform:scaleY(-1);' />

<div class='footnote footnote-white'>APÉNDICE C | COMPAÑEROS DEMONÍACOS</div>

\pagebreakNum

___
> ## Guardián de la Perdición
>*Demonio grande, caótico maligno*
> ___
> - **Clase de Armadura** 16 (coselete)
> - **Puntos de Golpe** 85 (9d10 + 36)
> - **Velocidad** 30 pies, vuelo 50 pies
> ___
>|  FUE  |  DES  |  CON  |  INT  |  SAB  |  CAR  |
>|:-----:|:-----:|:-----:|:-----:|:-----:|:-----:|
>|17 (+3)|15 (+2)|19 (+4)|13 (+1)|15 (+2)|22 (+6)|
>___
> - **Habilidades** Engaño +9, Intimidación +9
> - **Resistencias al Daño** contundente, perforante y cortante de armas no mágicas
> - **Inmunidades al Daño** fuego, veneno
> - **Inmunidades a Condiciones** envenenado
> - **Sentidos** visión en la oscuridad 60 pies, Percepción pasiva 12
> - **Idiomas** Eredun, Común
> - **Desafío** 7 (2,900 PX)
> ___
> ***Maestro del Dolor.*** Cuando el guardián de la perdición golpea a una criatura con su ataque de látigo por primera vez en una ronda, la criatura debe hacer una tirada de salvación de Constitución CD 14 o quedar inmovilizada por el dolor hasta el inicio de su siguiente turno. 
<br />&nbsp;&nbsp;&nbsp; Su velocidad se reduce a 10 pies y tiene desventaja en las tiradas de ataque. Si intenta lanzar un conjuro, debe hacer una tirada de salvación de Constitución CD 14 o el lanzamiento falla y el conjuro se desperdicia.
>
> ### Acciones
> ***Multiataque.*** El guardián de la perdición usa Presencia Aterradora. Luego realiza dos ataques, ya sea con su látigo o su rayo funesto.
>
> ***Látigo.*** *Ataque de Arma Cuerpo a Cuerpo:* +6 para golpear, alcance 15 pies, un objetivo. *Impacto:* 8 (2d4 + 3) de daño cortante más 13 (3d8) de daño psíquico. 
> 
> ***Rayo Funesto.*** *Ataque de Conjuro a Distancia:* +9 para golpear, alcance 120 pies, un objetivo. *Impacto:* 18 (4d8) de daño necrótico.
> 
> ***Presencia Aterradora.*** Cada criatura a elección del guardián de la perdición que esté a 120 pies de él y sea consciente de su presencia debe superar una tirada de salvación de Sabiduría CD 17 o quedar asustada durante 1 minuto. Una criatura puede repetir la tirada de salvación al final de cada uno de sus turnos, terminando el efecto para sí misma con éxito. Si una tirada de salvación de una criatura es exitosa o el efecto termina para ella, es inmune a la Presencia Aterradora del guardián de la perdición durante las siguientes 24 horas.

\columnbreak

___
> ## Infernal
>*Constructo grande, caótico maligno*
> ___
> - **Clase de Armadura** 17 (armadura natural)
> - **Puntos de Golpe** 73 (7d10 + 35)
> - **Velocidad** 30 pies
> ___
>|  FUE  |  DES  |  CON  |  INT  |  SAB  |  CAR  |
>|:-----:|:-----:|:-----:|:-----:|:-----:|:-----:|
>|20 (+5)| 8 (-1)|20 (+5)|12 (+1)|14 (+2)|11 (+0)|
> ___
> - **Resistencias al Daño** contundente, perforante y cortante de armas no mágicas que no sean de adamantina
> - **Inmunidades al Daño** fuego, veneno, psíquico
> - **Inmunidades a Condiciones** encantado, agotado, asustado, paralizado, petrificado, envenenado
> - **Sentidos** visión en la oscuridad 120 pies, Percepción pasiva 12
> - **Idiomas** entiende Eredun pero no puede hablar
> - **Desafío** 7 (2,900 PX)
> ___
> ***Muerte Explosiva.*** Cuando el infernal muere, explota, y cada criatura en un radio de 30 pies debe hacer una tirada de salvación de Destreza CD 15, recibiendo 10 (3d6) de daño por fuego si falla la salvación o la mitad si la supera. La explosión enciende objetos inflamables que no estén siendo llevados ni usados. 
> 
> ***Aura de Fuego.*** Al inicio de cada uno de los turnos del infernal, cada criatura a 5 pies de él recibe 3 (1d6) de daño por fuego, y los objetos inflamables en el aura que no estén siendo llevados ni usados se encienden. Una criatura que toque al infernal o lo golpee con un ataque cuerpo a cuerpo mientras esté a 5 pies recibe 3 (1d6) de daño por fuego.
> 
> ***Iluminación.***  El infernal emite luz brillante en un radio de 30 pies y luz tenue en otros 30 pies adicionales.
>
> ***Forma Inmutable.*** El infernal es inmune a cualquier conjuro o efecto que altere su forma.
> 
> ***Monstruo de Asedio.*** El infernal inflige el doble de daño a objetos y estructuras.
> 
> ### Acciones
> ***Multiataque.*** El infernal realiza dos ataques de golpe.
> 
> ***Golpe.*** *Ataque de Arma Cuerpo a Cuerpo:* +7 para golpear, alcance 5 pies, un objetivo. *Impacto:* 14 (2d8 + 5) de daño contundente más 3 (1d6) de fuego. Si el objetivo es una criatura u objeto inflamable, se enciende. Hasta que una criatura use una acción para apagar el fuego, el objetivo recibe 5 (1d10) de daño por fuego al inicio de cada uno de sus turnos.

<div class='footnote'>APÉNDICE C | COMPAÑEROS DEMONÍACOS</div>

\pagebreakNum

<div style='margin-top:170px;'></div>

## Guerrero
*Ahora, míralos atacarme. ¡Patéticos! ¿Creen que pueden tomar venganza por sus caídos? ¿Vienen a desafiarme a MÍ? Yo, que he ganado cien guerras. Yo, que me enfrenté solo contra miles y aún grité para que vinieran más enemigos. No, estos saurok se desplomarán ante mí como papel ante la llama.*
<div style="text-align:Right"> 

*— Skeer el Buscador de Sangre* <span style="margin-left:90px"></span></div>

Una humana con una armadura de placas resonante sostiene su escudo en alto mientras carga contra la masa de kóbolds. Un elfo de la noche detrás de ella, vestido con una armadura de cuero tachonado, lanza flechas hacia <br> los kóbolds desde su exquisito arco. El enano <br> cercano grita órdenes, ayudando a los dos <br> combatientes a coordinar su ataque.

Un orco con cota de malla interpone su escudo <br> entre el garrote del ogro y su compañero con un <br>rápido movimiento, desviando el golpe mortal. Su compañero, un elfo de sangre con armadura de escamas, blande dos cimitarras en un torbellino cegador mientras rodea al ogro, buscando un punto ciego en sus defensas.

Un gladiador lucha por deporte en una arena, maestro con su tridente y red, experto en derribar enemigos y moverlos para deleitar a la multitud y obtener una ventaja táctica. La espada de su oponente brilla con luz azul un instante antes de lanzar un rayo que lo impacta.

### Práctica Antigua
Mientras la guerra ha rugido a lo largo de los tiempos, héroes de todas las razas han buscado dominar su arte de la batalla. Los guerreros combinan fuerza, liderazgo y un vasto conocimiento de armas y armaduras para causar estragos en un glorioso combate. Algunos protegen desde las líneas frontales con escudos, reteniendo a los enemigos mientras los aliados apoyan desde atrás con hechizos y arcos. Otros prescinden del escudo y desatan su ira contra la amenaza más cercana con gran variedad de armas.

Los gritos de batalla del guerrero inspiran a sus amigos y dejan a sus enemigos temblando de miedo. Con precisión legendaria, los guerreros apuntan a los espacios más pequeños en la armadura y cortantendones en un desenfoque de acero. Cada dragón derrotado, tirano corrupto derribado y demonio desterrado de Azeroth ha temblado ante estos señores de la guerra.

Los guerreros son los luchadores temerarios por excelencia en el campo de batalla, y su destreza marcial pura inspira coraje en los aliados y desesperación en los enemigos. Expertos en todo tipo de armamento cuerpo a cuerpo y con una fuerza física y habilidad excepcionales, los Guerreros son combatientes ideales para servir como línea del frente y comandantes en el campo de batalla.

\columnbreak

<div style='margin-top:650px;'></div>

### Especialistas Versátiles
Los guerreros dominan los fundamentos de todos los estilos de combate. Pueden blandir un hacha, manejar una espada larga o un arco, luchar con un estoque, e incluso atrapar enemigos con una red. También son expertos en el uso de escudos y todo tipo de armaduras. Más allá de esta habilidad general, cada guerrero se especializa en un estilo específico. Algunos protegen a sus aliados de ataques mortales, otros luchan con dos armas a la vez, y algunos prefieren empuñar armas grandes con una fuerza impresionante. Esta combinación de habilidad general y especialización hace que los guerreros sean combatientes superiores tanto en el campo de batalla como en mazmorras.

### Creando un Guerrero
Al crear tu guerrero, piensa en dos elementos relacionados de su trasfondo: ¿Dónde recibiste tu entrenamiento de combate y qué te distingue de los combatientes mundanos a tu alrededor? ¿Fuiste particularmente despiadado? ¿Recibiste ayuda adicional de un mentor, tal vez debido a tu dedicación excepcional?

<div class='footnote'>PARTE 1 | CLASES</div>

<img src='https://www.gmbinder.com/images/C3YpaDn.jpg' style='position:absolute; top:0px; right:0px; width:700px' />
<img src='https://www.gmbinder.com/images/H47MOpD.png' style='position:absolute; top:0px; right:0px; width:900px' />
<img src='https://www.gmbinder.com/images/InB4SxN.png' style='position:absolute; top:-60px; right:-310px; width:800px' />

\pagebreakNum

<div class='classTable wide'>

##### El Guerrero
|Nivel| Bonificación de <br> competencia | Rasgos | Reserva de <br> Ira | Maniobras <br> Conocidas |
|:---:|:--:|:----------------------------------------|:--:|:-:|
| 1º  | +2  | Estilo de Combate, Segundo Aliento       |  —  | — |
| 2º  | +2  | Ira Interna                            |  1  | — |
| 3º  | +2  | Arquetipo Marcial, mejora de Ira       |  2  | 2 |
| 4º  | +2  | Mejora de Puntuación de Característica   |  2  | 2 |
| 5º  | +3  | Ataque Extra                             |  3  | 2 |
| 6º  | +3  | Acción Adicional (un uso)                |  3  | 3 |
| 7º  | +3  | Rasgo de Arquetipo Marcial               |  4  | 3 |
| 8º  | +3  | Mejora de Puntuación de Característica   |  4  | 3 |
| 9º  | +4  | —                                        |  5  | 3 |
|10º  | +4  | Indomable (un uso)                       |  5  | 3 |
|11º  | +4  | Rasgo de Arquetipo Marcial               |  6  | 4 |
|12º  | +4  | Mejora de Puntuación de Característica   |  6  | 4 |
|13º  | +5  | —                                        |  7  | 4 |
|14º  | +5  | Indomable (dos usos)                     |  7  | 4 |
|15º  | +5  | Rasgo de Arquetipo Marcial               |  8  | 4 |
|16º  | +5  | Mejora de Puntuación de Característica   |  8  | 5 |
|17º  | +6  | Acción Adicional (dos usos)              |  9  | 5 |
|18º  | +6  | Rasgo de Arquetipo Marcial               |  9  | 5 |
|19º  | +6  | Mejora de Puntuación de Característica   | 10  | 5 |
|20º  | +6  | Ataque Extra (2)                         | 10  | 5 |
</div>

&nbsp;&nbsp;&nbsp; Quizás recibiste entrenamiento formal en el ejército de un noble o en una milicia local. Tal vez te formaste en una academia militar, aprendiendo estrategia, tácticas e historia militar. O podrías ser autodidacta — sin refinar, pero probado en combate. ¿Tomaste la espada para escapar de la vida en una granja, o sigues una orgullosa tradición familiar? ¿De dónde obtuviste tus armas y armadura? Podrían haber sido equipo militar o reliquias familiares. O quizá ahorraste durante años para comprarlas. Tus armas son ahora tus posesiones más preciadas, lo único que se interpone entre tú y la muerte.
<div style='margin-top:-5px;'></div>

#### Creación Rápida
Haz que tu caracteristica principal sea Fuerza, seguida de Constitución.
<div style='margin-top:-5px;'></div>

#### Multiclase

***Caracteristica Mínima.*** Debes tener al menos un 13 en Fuerza o Destreza para coger un nivel en esta clase, o para coger un nivel en otra clase si ya eres guerrero.

***Competencias Ganadas.*** Armadura ligera, armadura media, escudos, armas simples y armas marciales.

\columnbreak

## Rasgos de Clase

#### Puntos de Golpe
___
- **Dado de golpe:** 1d10 por nivel de guerrero
- **PG a Nivel 1:** 10 + Mod. Constitución
- **PG por nivel:** 1d10 (o 6) + Mod. Constitución por cada nivel de guerrero

#### Competencias
___
- **Armadura:** Todas las armaduras, escudos
- **Armas:** Armas simples, armas marciales, armas de fuego
- **Herramientas:** Ninguna
- **Tiradas de salvación:** Fuerza, Constitución
- **Habilidades:** Elige dos habilidades de entre: Acrobacias, Adiestramiento de Animales, Atletismo, Historia, Perspicacia, Intimidación, Percepción y Supervivencia

#### Equipo
 - *(a)* cota de escamas o *(b)* cota de malla
 - *(a)* un arma marcial y un escudo o *(b)* dos armas marciales
 - *(a)* una ballesta ligera y 20 virotes o *(b)* dos hachas de mano
 - *(a)* un paquete de aventurero o *(b)* un paquete de explorador

<div class='footnote'>PARTE 1 | CLASES</div>

\pagebreakNum

### <span style="margin-left:70px"></span> Estilo de Combate
<span style="margin-left:72px">Adoptas un estilo particular de combate</span>
<span style="margin-left:70px">como tu especialidad. Elige una de las </span> 
<span style="margin-left:65px">siguientes opciones. No puedes elegir una</span> 
<span style="margin-left:60px">opción de Estilo de Combate más de una vez,</span>
<span style="margin-left:55px">incluso si tienes la opción de elegirla de nuevo.</span>
<div style='margin-top:20px;'></div>

#### <span style="margin-left:10px"></span> Defensa
<span style="margin-left:5px"></span> Mientras lleves armadura, obtienes un bono de +1 a la CA.

#### Duelo
Cuando empuñas un arma cuerpo a cuerpo en una mano y no tienes otras armas, obtienes un bono de +2 a las tiradas de daño con esa arma.

#### Gran Arma
Cuando obtengas un 1 o un 2 en un dado de daño por un ataque realizado con un arma cuerpo a cuerpo que empuñes con ambas manos, puedes volver a tirar el dado, pero debes usar el nuevo resultado, incluso si es un 1 o un 2. El arma debe tener la propiedad de dos manos o versátil para beneficiarte de esto.

#### Protección
Cuando una criatura que puedes ver ataca a un objetivo que no seas tú y que esté a 5 pies de ti, puedes usar tu reacción para imponer desventaja en la tirada de ataque. Debes estar empuñando un escudo.

#### Combate con Dos Armas
Cuando participes en combate con dos armas, puedes añadir tu modificador de habilidad al daño del segundo ataque.

### Segundo Aliento
Puedes recurrir a tu resistencia para protegerte del daño. Como acción adicional, puedes gastar un dado de golpe para recuperar puntos de golpe al instante, como si hubieras tomado un descanso corto, recuperando puntos de golpe equivalentes al total + tu modificador de Constitución.

### Ira Interna
Al alcanzar el nivel 2, aprendes a combatir con ferocidad abrumadora y puedes canalizar esa ira en tus ataques.

#### Ira
Ganas 1 punto de ira cuando infliges daño a una criatura con un ataque de arma que no hayas gastado puntos de ira en él. Puedes gastar estos puntos para realizar diversas maniobras. Para usar una de estas maniobras, debes gastar una cantidad de puntos de ira igual a su coste. No puedes tener más puntos de ira que tu nivel de Guerrero.

Tus puntos de ira acumulados permanecen durante 1 hora antes de disiparse, devolviendo tu reserva de ira a 0.

\columnbreak

#### Maniobras de Ira Conocidas
Empiezas conociendo tres maniobras: Carga, Desarme y Golpe Furioso, que se detallan a continuación.

La columna de Maniobras Conocidas en la tabla del Guerrero muestra cuándo aprendes nuevas maniobras de ira a tu elección. Las opciones de maniobras se detallan al final de la descripción de la clase.

Además, al ganar niveles en esta clase, puedes elegir una de las maniobras que has aprendido y reemplazarla con otra que puedas aprender en ese nivel. No puedes cambiar Carga, Desarme o Golpe Furioso.

#### Reserva de Ira
Puedes usar una acción adicional en tu turno para aprovechar tu reserva interna de ira y ganar un número de puntos de ira igual a la columna de Reserva de Ira en la tabla del Guerrero.

Una vez que uses tu reserva de ira, no puedes volver a usarla hasta que completes un descanso corto o largo.

#### Tirada de Salvación de Maniobras
Algunas de tus maniobras de ira requieren que tu objetivo realice una tirada de salvación para resistir el efecto. La CD de la tirada de salvación se calcula de la siguiente manera:

<div style="text-align: Center">

**CD de Ira** = <br>8 + Bonus competencia + Mod. Fuerza 
</div>

#### Maniobras de Ira
Empiezas conociendo tres maniobras de ira:

***Carga.*** Cuando realizas la acción de Correr y te desplazas al menos 20 pies hacia un objetivo, puedes gastar 1 punto de ira y realizar un ataque de arma contra él como parte de la acción de Correr. Este ataque se realiza con ventaja.

***Desarme.*** Puedes gastar 2 puntos de ira cuando hagas una tirada de ataque para intentar un golpe desarmador. Si el ataque impacta, infliges daño normal y el objetivo suelta un objeto de tu elección que esté sujetando.

***Golpe Furioso.*** Cuando hagas daño con un ataque de arma cuerpo a cuerpo, puedes gastar 1 o más puntos de ira para volver a tirar 1 dado de daño por cada punto de ira gastado. Debes usar el nuevo resultado.
<div style='margin-top:-3px;'></div>

### Arquetipo Marcial
Al alcanzar el nivel 3, eliges un arquetipo marcial que buscas emular en tus estilos y técnicas de combate. Elige entre Armas, Ira o Protección, todos detallados al final de la descripción de la clase. Tu arquetipo te concede rasgos en los niveles 3, 7, 11, 15 y 18.
<div style='margin-top:-3px;'></div>

<div class='footnote'>PARTE 1 | CLASES</div>
<img src='https://www.gmbinder.com/images/lDb6MoU.png' style='position:absolute; top:-125px; right:635px; width:290px; z-index:100' />

\pagebreakNum

### Mejora de Característica
Cuando alcanzas el nivel 4, y de nuevo en los niveles 8, 12, 16 y 19, puedes aumentar una característica a tu elección en 2, o puedes aumentar dos características en 1. No puedes aumentar una característica por encima de 20 usando este rasgo.
<div style='margin-top:-3px;'></div>

### Ataque Extra
A partir del nivel 5, puedes atacar dos veces, en lugar de una, siempre que realices la acción de Ataque en tu turno.

El número de ataques aumenta a tres cuando alcanzas el nivel 20 en esta clase.
<div style='margin-top:-3px;'></div>

### Acción Adicional
A partir del nivel 6, puedes superar tus límites normales por un momento. En tu turno, puedes realizar una acción adicional además de tu acción habitual y una posible acción adicional.

Una vez que uses este rasgo, debes completar un descanso corto o largo para usarlo de nuevo. Al alcanzar el nivel 17, puedes usarlo dos veces antes de un descanso, pero solo una vez por turno.

### Indomable
A partir del nivel 10, puedes volver a tirar una tirada de salvación fallida. Si lo haces, debes usar el nuevo resultado y no puedes usar este rasgo de nuevo hasta que completes un descanso largo.

Puedes usar este rasgo dos veces entre descansos largos a partir del nivel 14.

## Maniobras de Ira
Si una maniobra de ira tiene requisitos previos, debes cumplirlos para aprenderla. Puedes aprender la maniobra al mismo tiempo que cumples con sus requisitos. Un requisito de nivel se refiere a tu nivel en esta clase.

#### Ira Berserker
Puedes usar tu acción y gastar 3 puntos de ira para finalizar un efecto que te esté encantando o asustando.

#### Sed de Sangre
Cuando impactes a una criatura con un ataque de arma cuerpo a cuerpo, puedes gastar 3 puntos de ira para fortalecerte en el momento. Al hacerlo, ganas puntos de golpe temporales iguales a 1d8 + tu nivel de Guerrero. Estos puntos duran 1 minuto.

#### Cuchillada
*Requisito: 6º nivel*
<div style='margin-top:-6px;'></div>

Cuando golpeas a una criatura con un ataque de arma cuerpo a cuerpo, puedes gastar 4 puntos de ira para intentar atacar a otra criatura con el mismo ataque. Elige otra criatura a 5 pies del objetivo original y dentro de tu alcance. Si la tirada de ataque original impactaría al segundo objetivo, realiza el daño como un ataque normal.

\columnbreak

#### Heridas Profundas
*Requisito: 6º nivel*
<div style='margin-top:-6px;'></div>

Cuando impactes a una criatura con un ataque de arma cuerpo a cuerpo, puedes gastar 2 puntos de ira para intentar infligir una herida profunda. El objetivo debe superar una tirada de salvación de Constitución o perder 1d4 puntos de golpe debido a la pérdida de sangre. La herida profunda dura 1 minuto.

Al final de su turno, el objetivo pierde otros 1d4 puntos de golpe. Luego, realiza otra tirada de salvación de Constitución, deteniendo la hemorragia si tiene éxito.

#### Ejecutar
*Requisito: 6º nivel*
<div style='margin-top:-6px;'></div>

Cuando impactes a una criatura con un ataque de arma cuerpo a cuerpo, puedes gastar 6 puntos de ira para convertir tu ataque en un golpe crítico. Esto no tiene efecto si la tirada de ataque ya era crítica.

#### Golpe Potente
Cuando impactes a una criatura con un ataque de arma cuerpo a cuerpo, puedes gastar 2 puntos de ira para intentar forzar a un objetivo a retroceder. Si el objetivo es Grande o más pequeño, debe realizar una tirada de salvación de Fuerza. Si falla, lo empujas hasta 10 pies de distancia.

#### Corte Tendones
Cuando golpees a una criatura con un ataque de arma cuerpo a cuerpo, puedes gastar 2 puntos de ira para intentar derribar al objetivo. Si el objetivo es Grande o más pequeño, debe superar una tirada de salvación de Fuerza. Si falla, lo derribas.

#### Ignorar Dolor
Puedes usar tu reacción y gastar 3 puntos de ira cuando <br> recibas un ataque de arma para darte resistencia al daño contundente, perforante y cortante hasta el inicio de tu próximo turno.

#### Golpe Mortal
Cuando impactes a una criatura con un ataque de arma cuerpo a cuerpo, puedes gastar 2 puntos de ira para intentar asestar un golpe mortal. El objetivo debe superar una tirada de salvación de Constitución o no podrá recuperar puntos de golpe hasta el inicio de tu próximo turno.

#### Embate con Escudo
Cuando golpeas a una criatura con un ataque de arma cuerpo a cuerpo, puedes gastar 2 puntos de ira y usar tu acción adicional para golpear al objetivo con tu escudo, infligiendo daño igual a 1d4 + tu modificador de Fuerza.

Para ello, debes llevar un escudo.

## Arquetipos Marciales
Diferentes guerreros eligen distintos enfoques para perfeccionar su destreza en combate. El arquetipo marcial que elijas refleja tu enfoque.


\pagebreakNum

### Armas
Los guerreros de armas no se forjan en aulas, tabernas o talleres, sino en fosas de duelo y arenas de combate. Son luchadores pacientes que esperan para capitalizar los momentos en que su oponente queda expuesto. Muchos prefieren armas de dos manos, que les permiten asestar golpes devastadores y aprovechar al máximo las debilidades del enemigo.

#### Arrollar
A partir de que elijas este arquetipo al nivel 3, aprendes a usar tu arma como barrera. Cuando recibas un ataque cuerpo a cuerpo, puedes usar tu reacción para tirar 1d10 y sumar el resultado a tu CA. Si tu arrollamiento hace que el ataque falle, puedes realizar un ataque de arma contra el objetivo como parte de la misma reacción.

Puedes usar esta característica dos veces. Recuperas los usos gastados al completar un descanso corto o largo.

#### Intrépido
Al nivel 3, tu ira se regenera a medida que la viertes en tus ataques. Recuperas 1 punto de ira al final de tu turno si golpeas a una criatura con un movimiento de ira durante el mismo.

#### Grito de Mando
A partir del nivel 7, puedes comandar a un aliado para que ataque a tu objetivo. Como acción adicional, elige a una criatura aliada a 60 pies de ti que pueda verte o escucharte. Esa criatura puede usar su reacción para realizar un ataque cuerpo a cuerpo.

#### Golpe Colosal
Al alcanzar el nivel 11, cuando impactes a una criatura con un ataque cuerpo a cuerpo en tu turno, puedes destruir sus defensas y otorgar ventaja al próximo ataque de arma contra ese objetivo antes del final de tu próximo turno. Solo puedes usar Golpe Colosal una vez en cada turno.

#### Calma Mortal
A partir del nivel 15, instintivamente adoptas una postura defensiva en situaciones críticas. Mientras estés por debajo de la mitad de tus puntos de golpe máximos, tienes ventaja en las tiradas de salvación de Fuerza, Destreza o Constitución.

#### Golpes de Oportunidad
En el nivel 18, respondes con ferocidad a las aperturas en las defensas del enemigo. En combate, obtienes una reacción especial que puedes usar una vez en cada turno de criatura, excepto en el tuyo. Solo puedes usar esta reacción para realizar un ataque de oportunidad, y no puedes usarla en el mismo turno en el que uses tu reacción normal.

\columnbreak

### Ira
Los guerreros de ira son combatientes temidos, lanzándose al fragor de la batalla con un ansia por el combate, desatendiendo su defensa para asestar golpes brutales. Muchos prefieren armas que puedan blandirse con una sola mano, desatando una ráfaga de ataques para despedazar a sus enemigos.

#### Ira Desatada
Al elegir este arquetipo al nivel 3, puedes dejar de lado toda preocupación por la defensa para atacar con una desesperación feroz. Al realizar tu primer ataque en tu turno, puedes decidir desatar tu ira. Esto te otorga ventaja en tiradas de ataque cuerpo a cuerpo usando Fuerza durante ese turno, pero las tiradas de ataque contra ti también tendrán ventaja hasta tu próximo turno.

#### Temible
Al nivel 3, obtienes competencia en la habilidad de Intimidación si no la tienes ya. Cuando hagas una prueba de esta habilidad, puedes elegir usar tu modificador de Fuerza en lugar de tu modificador de Carisma.

#### Ira Focalizada
A partir del nivel 7, tu fuerza bruta te permite manejar armas con una potencia incomparable. 

Cuando uses un arma que inflige un único dado de daño, el dado de daño se incrementa en 1. Por ejemplo, una espada corta que normalmente inflige 1d6 de daño, en su lugar inflige 1d8 de daño. El dado de daño de un arma no puede incrementarse más allá de 1d12.

#### Sed de Sangre
Al nivel 11, cuando una criatura hostil a 20 pies de ti reciba daño, puedes usar tu reacción para moverte hasta la mitad de tu velocidad hacia ella sin provocar ataques de oportunidad. Si este movimiento te pone al alcance de la criatura, puedes realizar un ataque de arma contra ella como parte de la reacción.

#### Crítico Devastador
A partir del nivel 15, cuando consigas un golpe crítico con un ataque de arma, sumas un bono al daño igual a tu nivel en esta clase.

#### Berserker Enloquecido
En el nivel 18, si recibes daño que te reduce a 0 puntos de golpe y no te mata de inmediato, puedes usar tu reacción para retrasar la pérdida de consciencia y tomar un turno adicional de inmediato. Mientras tengas 0 puntos de golpe durante ese turno adicional, recibir daño provoca fallos en las tiradas de salvación de muerte como es habitual, y tres fallos pueden matarte. Al terminar el turno adicional, caes inconsciente si aún tienes 0 puntos de golpe. Una vez que uses esta característica, no puedes volver a usarla hasta que completes un descanso largo.

<div class='footnote'>PARTE 1 | CLASES</div>
<img src='https://www.gmbinder.com/images/z6WJzwY.jpg' style='position:absolute; top:920px; right:0px; width:800px'>
<img src='https://www.gmbinder.com/images/qV5FBIk.png' style='position:absolute; top:-85px; right:0px; width:900px; transform:scaley(-1)' />

\pagebreakNum

### Protección
Los guerreros de protección muestran una habilidad especial para usar el escudo, anulando los avances de sus oponentes y creando oportunidades para contraatacar. Para ellos, ser el soldado más resistente en el frente no significa nada si los aliados quedan vulnerables al ataque enemigo. Estos tenaces defensores son cruciales para el éxito de cualquier campaña militar.

#### Provocación
A partir de que elijas este arquetipo al nivel 3, puedes usar tu acción para provocar a criaturas en un radio de 30 pies. Toda criatura que elijas en el rango debe superar una tirada de salvación de Sabiduría contra la CD de tu Ira o tener desventaja en las tiradas de ataque contra criaturas que no seas tú durante 1 minuto. Una criatura puede repetir la salvación al final de cada uno de sus turnos, terminando el efecto si tiene éxito.

Una vez que uses esta característica, no puedes volver a usarla hasta que completes un descanso corto o largo.

#### Control de Ira
Al nivel 3, tu ira se renueva con los golpes que recibes. Cuando una criatura hostil te golpea con un ataque, ganas 1 punto de ira de inmediato. Solo puedes beneficiarte de este efecto una vez por turno.

#### Interceptar
A partir del nivel 7, cuando una criatura que puedes ver ataque a un objetivo que no seas tú y que esté a 5 pies de ti, puedes usar tu reacción para interceptar el ataque, forzando al atacante a dirigirse a ti en su lugar.

Puedes usar esta característica un número de veces igual a tu modificador de Constitución (mínimo de 1). Recuperas todos los usos gastados al completar un descanso largo.

#### Golpes Atenuados
A partir del nivel 11, incluso los golpes más fuertes no quebrarán tu defensa. Todo golpe crítico contra ti se convierte en un golpe normal y tienes ventaja en cualquier prueba o tirada de salvación para evitar ser derribado.

#### Presencia Inspiradora
A partir del nivel 15, puedes extender el beneficio de tu rasgo Indomable a un aliado. Cuando uses Indomable para repetir una tirada de salvación de Inteligencia, Sabiduría o Carisma y no estés incapacitado, puedes elegir a un aliado a 60 pies de ti que también haya fallado la tirada contra el mismo efecto. Si puede verte u oírte, puede repetir su tirada de salvación y debe usar el nuevo resultado.

#### Nunca Te Rindas
Al nivel 18, siempre que comiences tu turno con menos de la mitad de tus puntos de golpe máximos, ganas 1d10 + tu modificador de Constitución en puntos de golpe temporales. No obtienes este beneficio si tienes 0 puntos de golpe.


<div class='footnote'>PARTE 1 | CLASES</div>

\pagebreakNum

# Capítulo 3: Nuevos Trasfondos
### Boticario Oscuro
La Sociedad Real de Boticarios (S.R.B.) es una sociedad alquímica con sede en el Boticarium de Entrañas. Fue creada por Lady Sylvanas Brisaveloz con el objetivo de desarrollar una nueva plaga no-muerta para acabar con el Azote. Sus miembros son Renegados u otros tipos de no-muertos que se unieron a la causa de Sylvanas. Constantemente están elaborando nuevas plagas y venenos para lanzar sobre los enemigos de Sylvanas. Las demás razas de la Horda creen que trabajan en una cura para su "enfermedad". Los miembros de la Sociedad de Boticarios son llamados Boticarios o Boticarios Oscuros.

<br> **Competencias en habilidades:** Arcano, Investigación.
<br> **Competencia con herramientas:** Suministros de alquimista, equipo de venenos.
<br> **Equipo:** Suministros de alquimista o equipo de venenos, un brazalete con un frasco y una corona bordados, un cuaderno, un conjunto de túnicas de terciopelo negro y una bolsa con 15 po.

#### Característica: Agente de la S.R.B.
Tienes acceso a una red de simpatizantes y operativos bajo el respaldo de Lady Sylvanas Brisaveloz. En cualquier lugar donde haya Renegados, puedes encontrar Boticarios Oscuros dispuestos a ofrecer refugio, información, hierbas o ingredientes alquímicos. Sin embargo, este apoyo puede tener un costo, ya que podrían pedirte ayuda con una o más tareas a cambio.

#### Características Sugeridas
Probablemente tengas una naturaleza curiosa. Ya sea que busques una cura o un arma, es probable que luches por mejorar a los Renegados, aunque no necesariamente a la Horda. Recuerda que "mejor" no siempre significa "mejor para todos". Tu vínculo puede estar asociado con otros miembros de la Sociedad Real de Boticarios, o con un lugar u objeto importante para ella. El ideal por el que luchas probablemente esté alineado con los principios de la Sociedad, pero puede ser más personal en naturaleza.

|&nbsp;&nbsp;d8  |&nbsp;&nbsp;| Rasgo de Personalidad |
|:---:|-|:-----------|
|&nbsp; 1 || No digo que no a un experimento emocionante, a menos que yo sea el sujeto. |
|&nbsp; 2 || Los amigos son útiles. Necesito candidatos para experimentos. |
|&nbsp; 3 || No se puede deletrear "necromante" sin "romance". |
|&nbsp; 4 || Estoy dispuesto a curar a cualquiera, sin importar su lealtad. |
|&nbsp; 5 || Escondo mis planes siniestros tras una sonrisa tímida y una mirada gentil... de cuencas vacías. |
|&nbsp; 6 || Siempre tengo un plan para cuando las cosas salen mal. |
|&nbsp; 7 || Mi atención se dispersa porque siempre estoy un poco perdido en mis pensamientos. |
|&nbsp; 8 || Estoy siempre calmado, sin importar la situación. Nunca levanto la voz ni dejo que mis emociones me controlen. |

|&nbsp;&nbsp;d6  |&nbsp;&nbsp;| Ideal |
|:---:|-|:-----------|
|&nbsp; 1 || **Aspiración.** Demostraré mi valía ante Lady Sylvanas sin importar los sacrificios. (Cualquiera) |
|&nbsp; 2 || **Codicia.** A los muertos no les preocupa mucho el oro. (Maligno) |
|&nbsp; 3 || **Venganza.** Me mueve el deseo de vengar mi muerte. (Neutral) |
|&nbsp; 4 || **Honor.** Sé lo que la Sociedad espera de mí y lo cumpliré. (Legal) |
|&nbsp; 5 || **Belleza.** Lo que hago es arte, sin importar lo que piensen los demás. (Caótico) |
|&nbsp; 6 || **Cambio.** La maldición de la no-muerte debe terminar. (Bueno) |

|&nbsp;&nbsp;d6  |&nbsp;&nbsp;| Vínculo |
|:---:|-|:-----------|
|&nbsp; 1 || Encontrar una cura es lo único que importa. |
|&nbsp; 2 || Haré cualquier cosa para pagar mi deuda con Lady Sylvanas por liberarme del Azote. |
|&nbsp; 3 || Algún día me vengaré del Azote. |
|&nbsp; 4 || La Sociedad Real de Boticarios recuperará su antiguo estatus. |
|&nbsp; 5 || Incluso en la muerte, continuaré con el trabajo de mi vida. |
|&nbsp; 6 || Si se descubre mi verdadera misión, todo se perdería. |

|&nbsp;&nbsp;d6  |&nbsp;&nbsp;| Defecto |
|:---:|-|:-----------|
|&nbsp; 1 || Tengo tendencia a sobrepensar y complicar soluciones. |
|&nbsp; 2 || Me creo superior a los demás, y no tengo problema en señalarlo. |
|&nbsp; 3 || Soy dogmático en mis pensamientos y opiniones. |
|&nbsp; 4 || Tengo un deseo insaciable por los placeres carnales. |
|&nbsp; 5 || Nunca cuestiono las órdenes de mis superiores. |
|&nbsp; 6 || Mi orgullo probablemente me llevará a mi perdición. |

\pagebreakNum

### Doble Agente
Eres un informante para una facción u organización opuesta, proporcionándoles información falsa en nombre de otra organización a la que realmente eres leal. Podrías ser un informante para la Cruzada Escarlata, proporcionándoles información falsa en nombre de los Renegados. Quizá seas un miembro del Cártel Pantoque, proporcionando información falsa para asegurar que el cártel consiga las mejores oportunidades sin ser atrapados.

Habla con tu DM sobre las facciones/organizaciones con las que trabajas y contra las que actúas.

<br> **Competencias en habilidades:** Engaño, Perspicacia
<br> **Competencia con herramientas:** Kit de falsificación
<br> **Idiomas:** Puedes hablar Darnassiano, Draenei, Enano o Gnómico.
<br> **Equipo:** Kit de falsificación, daga, dos piezas de tiza, 4 hojas de pergamino, una botella de tinta, una pluma, un conjunto de ropa de viajero y una bolsa de cinturón con 15 po.

#### Característica: Dos Caras de Una Moneda
Tienes contactos en ambas organizaciones a las que proporcionas información. Las organizaciones oficiales a menudo te permiten cometer delitos menores sin temor a ser castigado, o manejar un negocio sin pagar todos los impuestos o tarifas habituales. Además, puedes obtener audiencias con funcionarios de ambas organizaciones.

#### Características Sugeridas
Trabajar para dos lados, escuchar las historias de cada uno y entregar información crucial, verdadera o falsa, no es una vida para todos. A menudo requiere dejar atrás conexiones personales y distanciarse de 'aliados' cercanos.

|&nbsp;&nbsp;d8 |&nbsp;&nbsp;| Rasgo de Personalidad |
|:-------------:|:-|:-----------|
|&nbsp; 1       || Las personas solo son tan valiosas como la información que poseen. |
|&nbsp; 2       || Me comporto de manera sofisticada y adecuada. |
|&nbsp; 3       || Ser sencillo me mantiene desapercibido y subestimado. |
|&nbsp; 4       || Siempre comparto con los necesitados. |
|&nbsp; 5       || Soy paranoico y un manojo de nervios. |
|&nbsp; 6       || Trato de reunir tanta información como pueda antes de actuar. |
|&nbsp; 7       || Me oculto tras una fachada, mostrando mi verdadero ser solo a amigos de confianza. |
|&nbsp; 8       || Estoy siempre calmado, sin importar la situación. Nunca alzo la voz ni dejo que mis emociones me controlen. |

|&nbsp;&nbsp;d6 |&nbsp;&nbsp;| Ideal |
|:-------------:|:-|:-----------|
|&nbsp; 1       || **Altruista.** Uso mi posición para ayudar a personas buenas a evitar la persecución o el abuso. (Bueno) |
|&nbsp; 2       || **Manipulador.** Utilizo secretos para manipular y chantajear a otros. (Maligno) |
|&nbsp; 3       || **Medios Justos.** Me ensucio las manos por un bien mayor. (Legal) |
|&nbsp; 4       || **Libertad.** Apoyo mi derecho y el de otros a hacer lo que queramos. (Caótico) |
|&nbsp; 5       || **Todos** tienen algo que ocultar, por eso no confío en nadie. (Neutral) |
|&nbsp; 6       || **Reservado.** Todos tienen secretos; nadie conocerá los míos. (Cualquiera) |

|&nbsp;&nbsp;d6 |&nbsp;&nbsp;| Vínculo |
|:-------------:|:-|:-----------|
|&nbsp; 1       || Me involucré en una red de mentiras para proteger a quienes amo. |
|&nbsp; 2       || Trabajo para socavar una organización opresora que daña mi hogar. |
|&nbsp; 3       || Me vi obligado a proporcionar información porque fui incriminado, así que encontré una manera de recuperar algo de mi libertad.|
|&nbsp; 4       || Mi familia depende de mi apoyo. |
|&nbsp; 5       || Estoy atrapado en juegos peligrosos debido a malas decisiones de un ser querido. |
|&nbsp; 6       || Necesito avanzar en mi posición dentro de mi organización. |

|&nbsp;&nbsp;d6 |&nbsp;&nbsp;| Defecto |
|:-------------:|:-|:-----------|
|&nbsp; 1       || Siempre pienso que estoy un paso por delante. |
|&nbsp; 2       || Veo agentes dobles en todas partes. |
|&nbsp; 3       || Me doy el gusto de cometer actos ilegales siempre que puedo. |
|&nbsp; 4       || Soy pesimista con todo. |
|&nbsp; 5       || Soy vengativo e impulsivo. |
|&nbsp; 6       || Soy temerario y busco emociones peligrosas. |

<div class='footnote'>PARTE 1 | NUEVOS TRASFONDOS</div>

\pagebreakNum

### Crianza en la Facción
Fuiste abandonado al nacer y encontrado por miembros de la facción opuesta, quienes te acogieron y criaron como uno de ellos. Aunque tuviste una infancia dura al ser rechazado por la facción, nunca fuiste completamente aceptado, solo tolerado en su presencia.

Podrías ser un tauren nacido en los reinos del este, abandonado por tus padres y hallado por granjeros humanos que te cuidaron y criaron como propio, o podrías ser un humano de Theramore que escapó de su hogar para ser acogido por orcos y criado como miembro de la Horda en Orgrimmar, aprendiendo a luchar y hablar el idioma de los orcos.

Habla con tu DM sobre los detalles de la facción y raza que te criaron, ya que no todas las razas de Azeroth tienen relaciones iguales con otras.

<br> **Competencias en habilidades:** Historia, Percepción
<br> **Idiomas:** Puedes hablar Darnassiano, 
<br>&nbsp;&nbsp;&nbsp; Draenei, Enano o Gnómico.
<br> **Equipo:** Un conjunto de ropa común, capa con capucha, 
<br>&nbsp;&nbsp;&nbsp; un amuleto de tu facción, libro, una botella de tinta, 
<br>&nbsp;&nbsp;&nbsp; una pluma y una bolsa con 10 po.

#### Característica: Lealtad Falsa
Tu raza y apariencia te permiten ingresar y pasar desapercibido en aldeas y ciudades de ambas facciones; aunque recibas miradas, nadie te detendrá ni te interrogará, ni levantará armas contra ti.

#### Características Sugeridas
Haber vivido entre razas de la facción opuesta, conociendo y apreciando sus costumbres, puede limitar las habilidades sociales dentro de su facción de nacimiento. No obstante, son individuos sociales que valoran a las razas con las que crecieron y luchan junto a ellas, incluso contra su propia gente.

|&nbsp;&nbsp;d8 |&nbsp;&nbsp;| Rasgo de Personalidad |
|:-------------:|:-|:-----------|
|&nbsp; 1       || Soy optimista y aprecio los gestos sencillos. |
|&nbsp; 2       || Soy cordial y hago un esfuerzo honesto para llevarme bien con mi nueva facción.|
|&nbsp; 3       || Sonrío a menudo, pero desconfío de las personas fuera de mi familia. |
|&nbsp; 4       || Soy callado y estudio intensamente a quienes me rodean. |
|&nbsp; 5       || Siempre estoy mirando por encima del hombro. |
|&nbsp; 6       || Me siento incómodo en ambientes urbanos y solo me siento seguro en caminos abiertos. |
|&nbsp; 7       || Soy amigable y extremadamente curioso. |
|&nbsp; 8       || Me encanta hablar con la gente y escuchar sus historias. |

|&nbsp;&nbsp;d6 |&nbsp;&nbsp;| Ideal |
|:-------------:|:-|:-----------|
|&nbsp; 1       || **Lealtad.** Nunca traiciono a un amigo, sin importar su lealtad. (Legal) |
|&nbsp; 2       || **Gente.** Ayudo a quienes me ayudan. (Cualquiera) |
|&nbsp; 3       || **Aspiración.** Probaré que soy digno de esta facción. (Bueno) |
|&nbsp; 4       || **Familia.** La sangre es más espesa que el agua. (Legal)|
|&nbsp; 5       || **Ira.** Fui abandonado y estoy enfadado con mi gente por dejarme atrás. (Maligno) |
|&nbsp; 6       || **Paz.** Todas las razas merecen paz. (Neutral) |

|&nbsp;&nbsp;d6 |&nbsp;&nbsp;| Vínculo |
|:-------------:|:-|:-----------|
|&nbsp; 1       || Mi familia lo es todo para mí. |
|&nbsp; 2       || Le debo todo a las personas que me acogieron y haría cualquier cosa por ellas. |
|&nbsp; 3       || Mis padres adoptivos fueron mejores que mis padres biológicos y los amo profundamente. |
|&nbsp; 4       || Me esfuerzo por encontrar algún día a los padres que me dejaron. |
|&nbsp; 5       || Debo demostrarme digno del amor de un miembro destacado de la familia. |
|&nbsp; 6       || Debo completar una gran hazaña para probar mi valía. |

|&nbsp;&nbsp;d6 |&nbsp;&nbsp;| Defecto |
|:-------------:|:-|:-----------|
|&nbsp; 1       || Me cuesta mucho confiar en los demás. |
|&nbsp; 2       || No siento simpatía por nadie de mi facción de nacimiento. |
|&nbsp; 3       || Me arrojo al peligro sin pensarlo. |
|&nbsp; 4       || Intento hablar para salir de cada situación. |
|&nbsp; 5       || Siempre confío en los de mi raza adoptiva. |
|&nbsp; 6       || Soy terriblemente tímido y me cuesta hablar con personas que no conozco. |

<div class='footnote'>PARTE 1 | PERSONALIDAD Y TRASFONDO</div>

\pagebreakNum

### Aprendiz del Kirin Tor
Has sido aceptado en el Kirin Tor, el grupo de magos más poderoso de Dalaran y de todo Azeroth. Pasaste tiempo en su escuela, obteniendo un mentor mago que supervisa tus estudios y guía tu aprendizaje.

Aprendiste los fundamentos de las escuelas de magia y las líneas de ley de la magia arcana que corren bajo la superficie de Azeroth. Has pasado suficiente tiempo en las bibliotecas del Kirin Tor, aprendiendo el conocimiento que más te interesaba, y tu mentor te ha enviado por Azeroth para buscar conocimiento y ganar experiencia.

<br> **Competencias en habilidades:** Arcanos, Historia
<br> **Competencia con herramientas:** Un tipo de herramientas de artesano
<br> **Idiomas:** Uno de tu elección
<br> **Equipo:** Una botella de tinta de alta calidad, una pluma, tiza, 
<br>&nbsp;&nbsp;&nbsp; un estuche para pergaminos con 5 hojas de pergamino, túnicas, 
<br>&nbsp;&nbsp;&nbsp; una vela, caja de yesca y una bolsa con 15 po.

#### Característica: Mentor Prominente
Conoces a un mago prominente dentro del Kirin Tor al que puedes recurrir en busca de respuestas e información. A discreción del DM, la información del mentor puede ser falsa, faltar detalles vitales o no responder de manera oportuna.

#### Características Sugeridas
Un aprendiz del Kirin Tor suele estar ansioso por aprender lo que hay en Azeroth, deseando obtener todo el conocimiento posible. Estos aprendices varían drásticamente en su personalidad, pero todos tienen algo en común: un profundo deseo de conocimiento y comprensión de la magia del mundo.

|&nbsp;&nbsp;d8 |&nbsp;&nbsp;| Rasgo de Personalidad |
|:-------------:|:-|:-----------|
|&nbsp; 1       || Soy callado y observador. |
|&nbsp; 2       || Comparo cualquier efecto mágico que vea con uno que he estudiado. |
|&nbsp; 3       || Menciono con frecuencia las enseñanzas de mis mentores. |
|&nbsp; 4       || Disfruto experimentar el mundo y evito estar encerrado en lugares silenciosos o aburridos. |
|&nbsp; 5       || Trato a los demás como si fueran poco inteligentes. |
|&nbsp; 6       || Tengo los ojos abiertos y me emociono con facilidad. |
|&nbsp; 7       || Me gusta usar palabras complejas para mostrar mi inteligencia. |
|&nbsp; 8       || Disfruto de un desafío intelectual. |

|&nbsp;&nbsp;d6 |&nbsp;&nbsp;| Ideal |
|:-------------:|:-|:-----------|
|&nbsp; 1       || **Protección.** La magia puede protegernos de todos los males del mundo. (Bueno) |
|&nbsp; 2       || **Poder.** El conocimiento puede convertirse en poder, y quiero más. (Maligno) |
|&nbsp; 3       || **Respeto.** La magia merece nuestros esfuerzos humildes por entenderla y dominarla. (Legal)|
|&nbsp; 4       || **Experimentación.** Nuevas y emocionantes magias esperan ser descubiertas. (Caótico) |
|&nbsp; 5       || **Conocimiento.** Entender el mundo que nos rodea es lo único que importa. (Neutral)|
|&nbsp; 6       || **Mejora Personal.** Lograré poder mágico a través del dominio propio y la comprensión. (Cualquiera)|

|&nbsp;&nbsp;d6 |&nbsp;&nbsp;| Vínculo |
|:-------------:|:-|:-----------|
|&nbsp; 1       || Seré conocido por mi poder, conocimiento y descubrimientos. |
|&nbsp; 2       || Demostraré ser superior a mis mentores. |
|&nbsp; 3       || Traeré honor y renombre a mi familia. |
|&nbsp; 4       || Descubriré nuevas magias que mi mentor nunca ha escuchado. |
|&nbsp; 5       || Un antiguo mentor era un monstruo; vengaré a sus víctimas. |
|&nbsp; 6       || He oído hablar de un pergamino que contiene el conocimiento que busco y debo encontrarlo. |

|&nbsp;&nbsp;d6 |&nbsp;&nbsp;| Defecto |
|:-------------:|:-|:-----------|
|&nbsp; 1       || Señalo los errores de los demás para hacerlos parecer pequeños y sentirme más grande. |
|&nbsp; 2       || No puedo resistir la oportunidad de aprender un nuevo hechizo o adquirir un nuevo objeto mágico. |
|&nbsp; 3       || Nunca aprendí habilidades sociales o de interacción adecuadas. |
|&nbsp; 4       || Uso hechizos y magia para hacer cosas que podría hacer con las manos. |
|&nbsp; 5       || Desprecio la autoridad y actúo de manera rebelde. |
|&nbsp; 6       || Estoy obligado a demostrar mi inteligencia superior. |

<div class='footnote'>PARTE 1 | NUEVOS TRASFONDOS</div>


\pagebreakNum

<style> .phb#p121:after { display:none; } </style>
<img src='https://www.gmbinder.com/images/80Bnl9r.jpg' style='position:absolute; top:0px; right:0px; width:800px' />

\pagebreakNum

# Capítulo 4: Nuevo Equipamiento
El mercado de una gran ciudad está lleno de compradores y vendedores de todo tipo: herreros enanos, talladores de madera elfos, talismanes trols, reliquias goblins y joyeros gnomos, sin mencionar humanos de todas las formas, tamaños y culturas. En las ciudades más grandes, casi cualquier cosa imaginable está a la venta, desde especias exóticas y ropa lujosa hasta cestas de mimbre, espadas y hermosos arcos élficos.

Para un aventurero, la disponibilidad de armaduras, armas, mochilas, cuerdas y otros bienes es crucial, ya que el equipo adecuado puede marcar la diferencia entre la vida y la muerte en una mazmorra o en las tierras salvajes. Este capítulo detalla la mercancía, tanto común como exótica, que los aventureros encuentran útil frente a las amenazas de Azeroth.

## Equipo Inicial
Al crear tu personaje, recibes equipo según una combinación de tu clase y tu trasfondo elegido. Alternativamente, puedes empezar con una cantidad de piezas de oro determinada por tu clase y gastarlas en objetos de las listas de este capítulo. Consulta la tabla de Riqueza Inicial por Clase para determinar cuánto oro tienes para gastar.

Decide cómo tu personaje obtuvo este equipo inicial. Podría haber sido una herencia, o bienes que adquirió durante su formación. Podrías haber recibido un arma, una armadura y una mochila como parte del servicio militar. Incluso podrías haber robado tu equipo. Un arma podría ser una reliquia familiar, transmitida de generación en generación hasta que tu personaje finalmente asumió el manto y siguió los pasos aventureros de un ancestro.

<div style='margin-top:50px;'></div>

<div class='classTable'>

##### Riqueza Inicial por Clase
|&nbsp; Clase        | Fondos      <span style="margin-left:75px"></span>|
|:-------------------|--------------------------------------------------:|
|&nbsp; Caballero de la Muerte | 4d4 x 10 po <span style="margin-left:75px"></span>|
|&nbsp; Cazador de Demonios | 2d4 x 10 po <span style="margin-left:75px"></span>|
|&nbsp; Druida        | 2d4 x 10 po <span style="margin-left:75px"></span>|
|&nbsp; Cazador       | 5d4 x 10 po <span style="margin-left:75px"></span>|
|&nbsp; Mago          | 4d4 x 10 po <span style="margin-left:75px"></span>|
|&nbsp; Monje         | 5d4 po      <span style="margin-left:75px"></span>|
|&nbsp; Paladín       | 5d4 x 10 po <span style="margin-left:75px"></span>|
|&nbsp; Sacerdote     | 4d4 x 10 po <span style="margin-left:75px"></span>|
|&nbsp; Pícaro        | 4d4 x 10 po <span style="margin-left:75px"></span>|
|&nbsp; Chamán        | 5d4 x 10 po <span style="margin-left:75px"></span>|
|&nbsp; Brujo         | 4d4 x 10 po <span style="margin-left:75px"></span>|
|&nbsp; Guerrero      | 5d4 x 10 po <span style="margin-left:75px"></span>|
</div>

## Armas Exóticas
Tu raza o clase puede otorgarte competencia con armas que no son comúnmente usadas por todas las razas o clases. Estas armas incluyen las espadas circulares lunares de los elfos nocturnos, los tótems de batalla tallados de los tauren y las icónicas gujas utilizadas por los cazadores de demonios.

### Competencia con Armas Exóticas
Tu raza, clase y dotes pueden otorgarte competencia con ciertas armas exóticas. Las armas exóticas son menos tradicionales y requieren un entrenamiento específico para cada arma, muchas de las cuales proporcionan beneficios específicos a cambio. Aunque requieren una competencia especial para usarse adecuadamente, un arma exótica funciona como un arma marcial para propósitos de efectos que especifican armas simples o marciales.

La competencia con un arma exótica te permite agregar tu bonificador de competencia a las tiradas de ataque que hagas con esa arma. Si haces una tirada de ataque con un arma exótica con la que no tienes competencia, no agregas tu bonificador de competencia a la tirada.

#### Nuevas Propiedades de Armas
Se describen aquí las nuevas propiedades de armas.

***Retumbante.*** La ignición del polvo en un arma de fuego crea un fuerte ruido, un destello de luz y un olor a explosivos quemados. Esta arma puede ser escuchada hasta 200 pies de distancia cuando se realiza una tirada de ataque a distancia con ella.

<div class='footnote'>PARTE 1 | NUEVO EQUIPAMIENTO</div>

\pagebreakNum

<div style='margin-top:115px;'></div>

<div class='classTable wide'>

##### Armas Exóticas
|&nbsp; Nombre                       | Coste |&nbsp;&nbsp;&nbsp;&nbsp;| Daño           | Peso   |&nbsp;&nbsp;&nbsp;&nbsp;| Propiedades |
|------------------------------------|------:|-|:---------------|------:|-|------------------------------|
|&nbsp; *Armas Cuerpo a Cuerpo*     |       ||                 |       ||
|&nbsp;&nbsp;&nbsp; Tótem de batalla | 50 po || 2d6 contundente | 16 kg || Especial, pesada, dos manos                            |
|&nbsp;&nbsp;&nbsp; Espada lunar     | 65 po || 2d4 cortante    | 2 kg  || Especial, sutil                                      |
|&nbsp;&nbsp;&nbsp; Guja lunar       | 25 po || 1d6 cortante    | 1 kg  || Especial, sutil, ligera, arrojadiza (rango 60/120)        |
|&nbsp;&nbsp;&nbsp; Doble hoja       |100 po || 1d6 cortante    | 2 kg  || Especial, versátil (1d8)                             |
|&nbsp;&nbsp;&nbsp; Garra de guerra  | 20 po || 1d6 cortante    | 1 kg  || Especial, sutil, ligera                               |
|&nbsp;&nbsp;&nbsp; Guja de guerra   | 25 po || 1d8 cortante    | 1,5 kg|| Arrojadiza (rango 20/60), versátil (1d10)                |
|&nbsp; *Armas a Distancia*         |       ||                 |       ||                                                       |
|&nbsp;&nbsp;&nbsp; Pistola          | 75 po || 1d8 perforante  | 1 kg  || Munición (rango 30/120), retumbante, recarga, ligera   |
|&nbsp;&nbsp;&nbsp; Rifle            | 75 po || 1d12 perforante | 3 kg  || Munición (rango 60/240), retumbante, recarga, <br> pesada, dos manos |
</div>

### Armas Exóticas
Las armas exóticas suelen ser únicas y distintas de cualquier arma simple o marcial. Cada arma exótica se describe a continuación.

***Tótem de batalla.*** Los tótems de batalla son troncos tallados intrincadamente. Sirven como elementos de importancia cultural, una pieza de arte e historia y una pesada arma contundente.

***Espada lunar.*** Las espadas lunares son hojas circulares de aproximadamente 2-1/2 pies de diámetro con un borde afilado que casi completa el círculo. Estas cuchillas crecientes son icónicas entre los guardianes elfos nocturnos y son el arma de un guerrero sumamente hábil.

***Guja lunar.*** Las gujas lunares son usadas por las centinelas elfas de la noche. El arma consta de tres cuchillas curvas que se extienden desde un mango central.

***Pistola.*** Las pistolas son cilindros metálicos cortos unidos a mangos robustos de hierro o madera. Aunque parecen simples, poseen mecanismos intrincados bajo su superficie.

***Rifle.*** Los rifles se parecen a las pistolas, pero con cañones metálicos que se extienden de 1 a 2 pies en comparación con las 3 pulgadas de una pistola. Gran parte del cañón de un rifle suele estar cubierto de madera.

***Doble hoja.*** Las dobles hojas son preferidas por los rompepiedras elfos de sangre. Constan de dos largas cuchillas que se extienden desde ambos extremos de un mango de longitud media.

***Garra de guerra.*** Las garras de guerra son comunes entre orcos, chamanes y ciertos monjes. Consisten en varias cuchillas de un pie de largo que se extienden desde un agarre que se sostiene en el puño, cubierto por un guantelete o guante protector.

***Guja de guerra.*** Las gujas de guerra son comunes entre los elfos nocturnos y elfos de sangre, y preferidas por los cazadores de demonios. La guja se compone de dos cuchillas en forma de media luna que se extienden en direcciones opuestas desde una empuñadura central.

#### Armas Especiales
Las armas con reglas especiales se describen aquí. Para utilizar estos efectos, debes ser competente con el arma.

***Tótem de Batalla.*** Si puedes lanzar conjuros, puedes usar esta arma como un foco de lanzamiento mientras la empuñas o la llevas. Además, el tótem de batalla funciona como un ariete portátil.

***Espada Lunar.*** Siempre que consigas agarrar a una criatura o ganar una prueba enfrentada de agarre mientras empuñas esta arma, infliges daño a la criatura como si hubieras acertado un ataque con arma.

***Guja Lunar.*** Cuando realices un ataque a distancia con esta arma y falles, la guja vuelve a tu mano al final de tu turno.

***Doble Hoja.*** Cuando realices un ataque con esta arma como parte de la acción de Ataque en tu turno, puedes usar una acción adicional inmediatamente después para hacer un ataque cuerpo a cuerpo extra con ella. Este ataque cuenta como un ataque con la mano secundaria a efectos de combate con dos armas.

***Garra de Guerra.*** Requiere una acción para equiparla o retirarla. Mientras esté equipada, no puedes ser desarmado de ella y tu mano se considera libre para sostener objetos o realizar componentes somáticos de conjuros. No puedes empuñar un arma ni sostener un escudo con la mano que tiene la garra de guerra equipada.


<div class='footnote'>PARTE 1 | NUEVO EQUIPAMIENTO</div>
<img src='https://www.gmbinder.com/images/MzuVWpF.png' style='position:absolute; top:-190px; right:275px; width:250px; transform:rotate(90deg)' />

\pagebreakNum

## Equipo de Aventurero
Esta sección describe elementos que tienen reglas especiales o requieren más explicación. Algunos objetos también han tenido un ajuste de precio para reflejar mejor su estado en Azeroth.

***Bayoneta.*** Esta hoja corta puede acoplarse al extremo de un arma de fuego o ballesta como una acción, permitiendo que el arma se use en un ataque cuerpo a cuerpo. Una bayoneta en un arma a distancia se trata como una lanza en términos de competencia y daño. Cuando se usa sola, se considera una daga.

&nbsp;&nbsp;&nbsp; ***Baliza.*** Una baliza es un invento de los manitas que parece una versión más grande de un farol. Emite luz brillante en un radio de 9 metros y luz tenue por 9 metros adicionales. Como acción, puedes encenderla o apagarla, o puedes bajar la capucha para reducir la luz a tenue en un radio de 1,5 metros.

***Bomba.*** Como acción, un personaje puede encender esta bomba y lanzarla a un punto hasta 18 metros de distancia. Cada criatura en un radio de 1,5 metros debe superar una tirada de salvación de Destreza CD 12 o recibir 2d6 de daño por fuego.

***Cajabuzz.*** Esta pequeña mochila permite al portador comunicarse con otras cajabuzz dentro de un radio de 8 km. El dispositivo es bloqueado por 30 cm de piedra, 2,5 cm de metal común, una lámina delgada de plomo o 1 metro de madera o tierra.

***Dinamita.*** Como acción, una criatura puede encender un palo de dinamita y lanzarlo a un punto hasta 18 metros de distancia. Cada criatura en un radio de 1,5 metros debe superar una tirada de salvación de Destreza CD 12 o recibir 4d6 de daño por trueno.

***Encendedor.*** Este pequeño contenedor puede producir una llama diminuta que emite luz brillante en un radio de 1,5 metros y luz tenue por 1,5 metros adicionales. Usarlo para encender una antorcha —o cualquier cosa con combustible expuesto— toma una acción.

***Linterna.*** Una linterna emite luz brillante en un cono de 18 metros y luz tenue por 18 metros adicionales. Como acción, puedes encenderla o apagarla.

***Vara de Luz.*** Una o más varas de luz pueden ser encendidas con tu acción, proporcionando luz brillante en un radio de 3 metros y luz tenue por 3 metros adicionales durante 8 horas. Una vez encendida, una vara de luz no puede ser apagada.

***Paracaídas.*** Una criatura que lleve este equipo en forma de mochila puede desplegarlo como reacción al caer. La velocidad de caída de la criatura se reduce a 18 metros por asalto hasta que aterrice, no recibe daño y la criatura se considera de un tamaño más grande a efectos de espacio. Una vez usado, el paracaídas toma 10 minutos para volver a ser empacado.

&nbsp;&nbsp;&nbsp; ***Mira.*** Una mira puede acoplarse a un arma de fuego de dos manos o a una ballesta en 1 minuto. Puedes usar tu acción adicional para apuntar a través de la mira, eliminando la desventaja de atacar a larga distancia hasta el final de tu turno.

***Kit de Sutura.*** Un kit de sutura es una pequeña colección de agujas e hilos de origen cuasi-mágico. Un renegado puede usarlo para volver a unir partes del cuerpo o reparar daños en su cuerpo. También puede usar el kit para unir partes de otros cadáveres a sí mismo, siempre que la parte coincida con una parte faltante en su cuerpo. Usar este kit normalmente requiere una prueba exitosa de Sabiduría (Medicina) y toma desde unos minutos hasta varias horas, dependiendo del procedimiento.

##### Kit de Sutura
|&nbsp; Procedimiento de Sutura | CD &nbsp;&nbsp;&nbsp;|
|:---|:-----------:|
|&nbsp; Coser o reparar piel   | 10 &nbsp;&nbsp;&nbsp;|
|&nbsp; Reunir miembro propio  | 15 &nbsp;&nbsp;&nbsp;|
|&nbsp; Adjuntar un nuevo miembro en lugar del propio | 20 &nbsp;&nbsp;&nbsp;|

#### Herramientas de Armero
Las herramientas de armero permiten a un personaje crear armas de fuego y producir munición.

***Componentes.*** Las herramientas de armero incluyen un martillo de bola, juegos de destornilladores, punzones, limas y alicates, gafas de seguridad con lentes amplificadores, reglas y escuadras, varillas de limpieza, botellas de grasa y aceite, un cuerno de pólvora, un pequeño mortero y pilón, y finalmente, tornillos y muelles.

***Fabricación de Armas de Fuego.*** Si eres competente con las herramientas de armero, puedes fabricar una pistola o rifle en el transcurso de una semana laboral (5 días de 8 horas de trabajo) gastando 50 po en materiales y recursos.

***Fabricación de Balas.*** Si eres competente con las herramientas de armero, como parte de un descanso largo, puedes fabricar balas en lotes de 6 + el doble de tu bonificador de competencia. Necesitas gastar 1 po en materiales por cada lote que fabriques.

<img src='https://www.gmbinder.com/images/gJg0VCn.jpg' style='position:absolute; top:480px; right:-270px; width:900px' />
<img src='https://www.gmbinder.com/images/1Ns1K1B.png' style='position:absolute; top:0px; right:-50px; width:950px' />

\pagebreakNum

<div style='margin-top:50px;'></div>

<div class='classTable'>

##### Nuevo Equipo de Aventurero
|&nbsp; Nombre                          | Coste |&nbsp;&nbsp;&nbsp;| Peso &nbsp;|
|---------------------------------------|------:|-|------------:|
|&nbsp; *Nueva Munición*                |       ||        &nbsp;|
|&nbsp;&nbsp;&nbsp; Balas (20) |  2 po ||  1 kg &nbsp;|
|&nbsp; Bayoneta                        |  2 po ||  0,5 kg &nbsp;|
|&nbsp; Bomba                           | 75 po ||  1 kg &nbsp;|
|&nbsp; Baliza                          | 50 po ||  1 kg &nbsp;|
|&nbsp; Libro                           | *~~25 po~~* 10 po ||  2,5 kg &nbsp;|
|&nbsp; Botella, vidrio                 | *~~2 po~~* 1 pc ||  1 kg &nbsp;|
|&nbsp; Cajabuzz                        |2,000 po||  5 kg &nbsp;|
|&nbsp; Cadena (3 metros)               | *~~5 po~~* 2 po ||  5 kg &nbsp;|
|&nbsp; Dinamita                        |200 po ||  0,5 kg &nbsp;|
|&nbsp; Encendedor                      | 25 po ||      — &nbsp;|
|&nbsp; Linterna                        | 50 po ||  1 kg &nbsp;|
|&nbsp; Vara de luz                     |  5 pc ||      — &nbsp;|
|&nbsp; *Nuevos Símbolos Sagrados*      |       ||        &nbsp;|
|&nbsp;&nbsp;&nbsp; Libram              | 10 po ||  2,5 kg &nbsp;|
|&nbsp; Reloj de arena                  | *~~25 po~~* 2 po ||  0,5 kg &nbsp;|
|&nbsp; Tinta (botella de 1 onza)       | *~~10 po~~* 4 po ||       — &nbsp;|
|&nbsp; Lupa                            | *~~100 po~~* 5 po ||       — &nbsp;|
|&nbsp; Espejo, acero                   | *~~5 po~~* 2 pc || 0,25 kg &nbsp;|
|&nbsp; Papel (una hoja)                | *~~2 pc~~* 1 pc ||       — &nbsp;|
|&nbsp; Pergamino (una hoja)            | *~~1 pc~~* 5 mc ||       — &nbsp;|
|&nbsp; Paracaídas                      | 30 po ||  7,5 kg &nbsp;|
|&nbsp; Mira                            | 60 po ||  0,5 kg &nbsp;|
|&nbsp; Anillo con sello                | *~~5 po~~* 2 po ||       — &nbsp;|
|&nbsp; Catalejo                        | *~~5~~* 2 po ||      — &nbsp;|
|&nbsp; Kit de sutura                   | 25 po ||  1,5 kg  &nbsp;|
|&nbsp; Reloj                           | 25 po ||      — &nbsp;|
|&nbsp; Vial                            | *~~1 po~~* 5 mc ||       — &nbsp;|
</div>

\columnbreak

<div style='margin-top:50px;'></div>

<div class='classTable'>

##### Nuevas Herramientas
|&nbsp; Nombre                          | Coste |&nbsp;&nbsp;&nbsp;| Peso &nbsp;|
|---------------------------------------|------:|-|------------:|
|&nbsp; *Herramientas de Artesano*      |       ||        &nbsp;|
|&nbsp;&nbsp;&nbsp; Herramientas de armero | 25 po ||  5 kg &nbsp;|
|&nbsp; *Set de Juegos*                 |       ||        &nbsp;|
|&nbsp;&nbsp;&nbsp; Set de cartas de Hearthstone |  5 po ||      — &nbsp;|
|&nbsp;&nbsp;&nbsp; Set de jihui pandaren |  5 po ||  1 kg &nbsp;|
</div>

\pagebreakNum

# Capítulo 5: Personalización
Un dote representa un talento o un área de especialización que otorga a un personaje capacidades especiales. Encierra entrenamiento, experiencia y habilidades que van más allá de lo que una clase proporciona. En ciertos niveles, tu clase te otorga una Mejora de Característica. Usando la regla opcional de dotes, puedes renunciar a tomar esa característica para elegir un dote de tu elección. Solo puedes tomar cada dote una vez, a menos que la descripción del dote diga lo contrario.

Debes cumplir con cualquier requisito específico de un dote para tomarlo. Si alguna vez pierdes el requisito de un dote, no puedes usarlo hasta que vuelvas a cumplir con el requisito. Por ejemplo, el dote Mago de Batalla requiere que puedas lanzar un conjuro. Si pierdes tu capacidad de lanzar conjuros de alguna manera, no puedes beneficiarte del dote Mago de Batalla hasta que esa habilidad sea restaurada.

Los dotes presentados en este libro son complementos a los presentados en el *Manual del Jugador* de la 5ª edición.

### Mago de Batalla
*Requisito: La capacidad de lanzar al menos un conjuro*
<div style='margin-top:-7px;'></div>

 - Dos trucos extra de la lista de conjuros de mago.
 - Cuando realices un ataque de conjuro a distancia, no sufres desventaja en la tirada de ataque si estás a 1,5 metros de una criatura hostil.
 - Antes de lanzar un conjuro instantáneo que requiera una tirada de ataque y que no pueda impactar a más de un objetivo, puedes optar por recibir una penalización de -5 a la tirada de ataque del conjuro. Si el conjuro impacta, añades +10 al daño del conjuro.

### Experto en Armas de Fuego
 - Ignoras la propiedad de recarga de las armas de fuego con las que eres competente.
 - Estar a 1,5 metros de una criatura hostil no impone desventaja en tus tiradas de ataque a distancia.
 - Cuando usas la acción de Ataque y atacas con un arma de una mano, puedes usar una acción adicional para atacar con un arma de fuego cargada de una mano que estés sosteniendo.

### Adepto en Armas de Fuego
 - Destreza o Inteligencia +1, hasta un máximo de 20.
 - Competencia con herramientas de armero.
 - Competencia con armas de fuego.

### Maestro en Armas Exóticas
 - Fuerza o Destreza +1, hasta un máximo de 20.
 - Competencia con cuatro armas exóticas de tu elección.

\columnbreak

## Dotes Raciales
Subir de nivel en una clase es la principal forma en que un personaje evoluciona durante una campaña. Algunos DM también permiten el uso de dotes para personalizar un personaje. Los dotes son una regla opcional del capítulo 6 del *Manual del Jugador*. El DM decide si se usan y puede también decidir que algunos dotes estén disponibles en una campaña y otros no.

Esta sección presenta una colección de dotes especiales que te permiten explorar más a fondo la raza de tu personaje. Estos dotes están asociados con una raza del capítulo 1, como se resume en la tabla de Dotes Raciales. Un dote racial representa una conexión más profunda con la cultura de tu raza o una transformación física que te acerca a un aspecto de tu linaje racial.

La causa de una transformación particular depende de ti y de tu DM. Un dote transformacional puede simbolizar una cualidad latente que emerge con la edad, o puede ser el resultado de un evento en la campaña, como la exposición a una poderosa magia o visitar un lugar de gran significado para tu raza. Descubrir por qué tu personaje ha cambiado puede ser una adición enriquecedora su historia.

##### Dotes Raciales
|&nbsp; Raza               | Dote                 |
|:-------------------------|:---------------------|
|&nbsp; Cualquier Raza     | Rencor de Facción    |
|&nbsp; Elfo de sangre     | Teletransporte Arcano|
|&nbsp; Enano              | Fortaleza Enana      |
|&nbsp; Enano              | Agilidad Robusta     |
|&nbsp; Enano (Martillo Salvaje) | Guía Espiritual   |
|&nbsp; Elfo               | Precisión Élfica     |
|&nbsp; Renegado (elfo)    | Teletransporte Arcano|
|&nbsp; Renegado (elfo)    | Precisión Élfica     |
|&nbsp; Renegado (humano)  | Prodigio             |
|&nbsp; Gnomo              | Agilidad Robusta     |
|&nbsp; Goblin             | Mejor Química        |
|&nbsp; Goblin             | Agilidad Robusta     |
|&nbsp; Humano             | Prodigio             |
|&nbsp; Elfo nocturno      | Amigo de las Criaturas|
|&nbsp; Elfo nocturno      | Herencia Darnassiana |
|&nbsp; Nocheterna         | Teletransporte Arcano|
|&nbsp; Orco               | Furia Orca           |
|&nbsp; Orco               | Guía Espiritual      |
|&nbsp; Tauren             | Resistencia Tauren   |
|&nbsp; Tauren             | Guía Espiritual      |
|&nbsp; Trol               | Guía Espiritual      |
|&nbsp; Elfo del Vacío     | Abrazo del Vacío     |
|&nbsp; Huargen            | Depredador Endurecido|

<div class='footnote'>PARTE 1 | OPCIONES DE PERSONALIZACIÓN</div>


\pagebreakNum

### Teletransporte Arcano
*Requisito: Elfo de sangre, renegado (elfo) o nocheterna*
<div style='margin-top:-5px;'></div>

 - Inteligencia o Carisma +1, hasta un máximo de 20.
 - Aprendes el conjuro *paso brumoso* y puedes lanzarlo una vez sin gastar un espacio de conjuro. Recuperas la habilidad de lanzarlo de esta manera al finalizar un descanso corto o largo. La habilidad de lanzamiento de conjuros para este hechizo es Inteligencia.

### Mejor Química
*Requisito: Goblin*
<div style='margin-top:-5px;'></div>

 - Inteligencia +1, hasta un máximo de 20.
 - Competencia con suministros de alquimista. Si ya tienes competencia con ellos, tu bonus de competencia se duplica en las pruebas que hagas con ellos.
 - Como acción, puedes identificar una poción que esté a 1,5 metros de ti, como si la hubieras probado. Debes ver el líquido para que este beneficio funcione.
 - Durante un descanso corto, puedes mejorar temporalmente la potencia de una poción de curación de cualquier rareza. Debes tener suministros de alquimista contigo para mejorar la potencia de la poción, y la poción debe estar al alcance. Durante 1 hora después de que termine el descanso corto, una criatura que beba la poción puede optar por no tirar los dados de la poción y recuperar el máximo de puntos de golpe que puede restaurar.

### Amigo de las Criaturas
*Requisito: Elfo nocturno*
<div style='margin-top:-5px;'></div>

 - Competencia en de Manejo de Animales. Si ya eres competente en ella, tu bonus de competencia se duplica en cualquier prueba que hagas con ella.
 - Aprendes el conjuro *hablar con animales* y puedes lanzarlo a voluntad, sin gastar un espacio de conjuro. También aprendes el conjuro *amistad con los animales* y puedes lanzarlo una vez con este dote, sin gastar un espacio de conjuro. Recuperas la habilidad de lanzarlo de esta manera al finalizar un descanso largo. La habilidad de lanzamiento de conjuros para estos hechizos es Sabiduría.

### Herencia Darnassiana
*Requisito: Elfo nocturno*
<div style='margin-top:-5px;'></div>

 - Inteligencia o Sabiduría +1, hasta un máximo de 20.
 - Ventaja en las pruebas de Destreza (Sigilo) realizadas en áreas con luz tenue o sin luz.
 - Cuando falles una tirada de salvación contra la muerte, puedes invocar un espíritu para cambiar el dado a un éxito. La esencia del espíritu persiste en tu cuerpo durante tus dos siguientes descansos largos, impidiéndote invocar la ayuda de otro.

\columnbreak

### Fortaleza Enana
*Requisito: Enano*
<div style='margin-top:-5px;'></div>

 - Constitución +1, hasta un máximo de 20.
 - Siempre que tomes la acción de Esquivar en combate, puedes gastar un dado de golpe para curarte. Tira el dado, añade tu modificador de Constitución y recupera una cantidad de puntos de golpe igual al total (mínimo de 1).

### Precisión Elfica
*Requisito: Cualquier elfo o renegado (elfo)*
<div style='margin-top:-5px;'></div>

 - Destreza, Inteligencia, Sabiduría o Carisma +1, hasta un máximo de 20.
 - Siempre que tengas ventaja en una tirada de ataque con Destreza, Inteligencia, Sabiduría o Carisma, puedes volver a tirar uno de los dados una vez.

### Abrazo del Vacío
*Requisito: Elfo del Vacío*
<div style='margin-top:-5px;'></div>

 - Inteligencia, Sabiduría o Carisma +1, hasta un máximo de 20.
 - Cuando tires daño necrótico para un conjuro que lanzas, puedes volver a tirar cualquier resultado de 1 en los dados de daño necrótico, pero debes usar el nuevo resultado, incluso si es otro 1.
 - Cuando lanzas un conjuro que inflige daño necrótico, puedes hacer que el vacío te envuelva hasta el final de tu próximo turno. El vacío no te daña y reduce toda luz en un radio de 9 metros a oscuridad, y la luz dentro de un radio adicional de 9 metros a luz tenue. Mientras el vacío está presente, cualquier criatura que esté a 1,5 metros de ti y te golpee con un ataque cuerpo a cuerpo recibe 1d4 de daño.

### Rencor de Facción
*Requisito: Cualquier raza*
<div style='margin-top:-5px;'></div>

Sientes un profundo odio hacia un miembro particular de la facción opuesta. Elige dos razas de la facción opuesta que sean objeto de tu ira (cada raza incluye todas sus subrazas). Obtienes los siguientes beneficios:
 - Fuerza, Constitución o Sabiduría +1, hasta un máximo de 20.
 - Durante el primer asalto de combate contra tus enemigos elegidos, tus tiradas de ataque contra ellos tienen ventaja.
 - Cuando cualquiera de tus enemigos elegidos haga un ataque de oportunidad contra ti, hace la tirada de ataque con desventaja.
 - Cuando realices una prueba de Inteligencia (Arcano, Historia, Naturaleza o Religión) para recordar información sobre tus enemigos elegidos, añades el doble de tu bonificador de competencia a la prueba, incluso si normalmente no eres competente en la habilidad.

<div class='footnote'>PARTE 1 | OPCIONES DE PERSONALIZACIÓN</div>

\pagebreakNum

### Depredador Endurecido
*Requisito: Huargen*
<div style='margin-top:-5px;'></div>

 - Ventaja en las pruebas de Sabiduría (Percepción) que dependan del olfato.
 - Mientras tengas ambas manos vacías, puedes usar la acción de Correr como acción adicional, desplazándote a cuatro patas.
 - Tus garras crecen y se convierten en armas naturales, que puedes usar para realizar golpes desarmados. Si impactas con ellas, infliges daño cortante igual a 1d4 + tu modificador de Fuerza, en lugar del daño contundente normal de un golpe desarmado.
 - Si realizas un ataque de mordisco como acción, puedes usar tu acción adicional para realizar un ataque con tus garras.

### Furia Orca
*Requisito: Orco*
<div style='margin-top:-5px;'></div>

 - Fuerza o Constitución +1, hasta un máximo de 20.
 - Cuando golpees con un ataque realizado con un arma simple o marcial, puedes tirar uno de los dados de daño del arma una vez más y añadirlo como daño adicional del mismo tipo que el del arma. Una vez uses esta habilidad, no puedes usarla de nuevo hasta que termines un descanso corto o largo.
 - Inmediatamente después de usar tu rasgo Resistencia Implacable, puedes realizar un ataque con arma como reacción.

### Prodigio
*Requisito: Renegado (humano) o humano*
<div style='margin-top:-5px;'></div>

 - Competencia en una habilidad de tu elección, competencia en una herramienta de tu elección y fluidez en un idioma de tu elección.
 - Elige una habilidad en la que tengas competencia. Obtienes pericia con esa habilidad. La habilidad elegida no puede ser una que ya esté beneficiándose de una característica, como Pericia, que duplique tu bonificador de competencia.

\columnbreak

### Guía Espiritual
*Requisito: Enano (Martillo Salvaje), orco, tauren o trol*
<div style='margin-top:-5px;'></div>

 - Sabiduría o Carisma +1, hasta un máximo de 20.
 - Ventaja en las tiradas de salvación contra el miedo.
 - Aprendes el conjuro *espíritu sanador* y puedes lanzarlo una vez con este dote, sin gastar un espacio de conjuro. Recuperas la capacidad de lanzarlo de esta manera al finalizar un descanso largo. La habilidad de lanzamiento de conjuros para este hechizo es Sabiduría.

### Agilidad Robusta
*Requisito: Enano, gnomo o goblin*
<div style='margin-top:-5px;'></div>

 - Fuerza o Destreza +1, hasta un máximo de 20.
 - Aumenta tu velocidad en 1,5 metros.
 - Competencia en Acrobacias o Atletismo (tu elección).
 - Ventaja en cualquier prueba de Fuerza (Atletismo) o Destreza (Acrobacias) que realices para escapar de un agarre.

### Resistencia Tauren
*Requisito: Tauren*
<div style='margin-top:-5px;'></div>

 - Fuerza, Destreza o Constitución +1, hasta un máximo de 20.
 - Tu piel se engrosa. Mientras no lleves armadura, puedes calcular tu CA como 10 + tu modificador de Destreza + tu modificador de Constitución. Puedes usar un escudo y seguir beneficiándote de esta característica.
 - Tu máximo de puntos de golpe aumenta en una cantidad igual a tu nivel cuando adquieras este dote. Siempre que ganes un nivel a partir de entonces, tu máximo de puntos de golpe aumenta en 1 punto adicional.

<div class='footnote'>PARTE 1 | OPCIONES DE PERSONALIZACIÓN</div>
<img src='https://www.gmbinder.com/images/yeTeNNY.jpg' style='position:absolute; top:750px; right:-100px; width:1150px' />
<img src='https://www.gmbinder.com/images/3e9S91s.png' style='position:absolute; top:-120px; right:0px; width:800px' />

\pagebreakNum

# Capítulo 6: Conjuros
Este capítulo describe los conjuros más comunes en Azeroth. El capítulo comienza con las listas de conjuros de las clases lanzadoras de conjuros. El resto contiene descripciones de conjuros, presentadas en orden alfabético por el nombre del conjuro.

Aunque la mayoría de las descripciones de conjuros se encuentran en el *Manual del Jugador*, algunos conjuros se describen en otros lugares, como se indica en la tabla a continuación.

Símbolo|Ubicación del Conjuro
------|--------------------------
✦ | En este capítulo, bajo Descripciones de Conjuros
^EGW^ | *Guía del Explorador de Wildemount*
^ID:RotF^ | *Icewind Dale: Rime of the Frostmaiden*
^LLK^ | *Laboratorio Perdido de Kwalish*
^SCAG^ | *Guía del Aventurero de la Costa de la Espada*
^TCE^ | *Caldero de Todo de Tasha*
^XGE^ | *Guía de Todo de Xanathar*


\pagebreakNum

### Caballero de la Muerte

<div class='spellList'>

##### Nivel 1
- Absorber Elementos ^XGE^
- Anatema
- Causar Miedo ^XGE^
- ✦ Cadenas de Hielo
- Comando
- Duelo Compulsivo
- ✦ Explosión de Cadáveres
- ✦ Agarre de la Muerte
- Detectar el Bien y el Mal
- Detectar Magia
- Detectar Veneno y Enfermedad
- ✦ Favor Aterrador
- Nube de Niebla
- Heroísmo
- Cuchillo de Hielo ^XGE^
- ✦ Toque Helado
- Protección contra el Bien y el Mal
- Rayo de Enfermedad
- Golpe Trueno
- Golpe Furioso

\columnbreak

##### Nivel 2
- ✦ Cáscara Antimágica
- Augurio
- Ceguera/Sordera
- ✦ Hervor de Sangre
- Calmar Emociones
- Corona de Locura
- Visión en la Oscuridad
- Encontrar Corcel
- Reposo Gentil
- Sujetar Persona
- ✦ Explosión Aullante
- ✦ Fortaleza de Hielo
- Rayo de Debilitamiento
- Silencio
- Tormenta de Bolas de Nieve de Snilloc ^XGE^
- Zona de Verdad

\columnbreak

##### Nivel 3
- Animar a los Muertos
- ✦ Asfixiar
- Bestow Curse
- Clarividencia
- Disipar Magia
- Enemigos en Abundancia ^XGE^
- Miedo
- Fingir Muerte
- Forma Gaseosa
- Transferencia de Vida ^XGE^
- ✦ Manto del Cruzado Caído
- Corcel Fantasma
- Tormenta de Granizo
- Hablar con los Muertos
- Toque Vampírico
- Caminar sobre el Agua

\columnbreak

##### Nivel 4
- Ojo Arcano
- Destierro
- Marchitar
- ✦ Conjurar No-Muertos
- ✦ Muerte y Decadencia
- Protección contra la Muerte
- Adivinación
- ✦ Dominar No-Muertos
- Encontrar Corcel Mayor ^XGE^
- Tormenta de Hielo
- Asesino Fantasmal
- Radiancia Enferma ^XGE^
- Golpe Devastador
- Piel de Piedra
- Esfera Vitriólica ^XGE^

</div>

##### Nivel 5
Cáscara Antivida
<br> ✦ Ejército de los Muertos
<br> Golpe Desterrador
<br> Círculo de Poder
<br> Danza Macabra ^XGE^
<br> ✦ Cadena de Muerte
<br> ✦ Furia de la Serpiente de la Muerte
<br> Disipar el Bien y el Mal
<br> Agotamiento ^XGE^
<br> Sacralizar
<br> Sujetar Monstruo
<br> Inundación de Energía Negativa ^XGE^
<br> ✦ Arma Impía

\columnbreak

<div style='margin-top:70px;'></div>

> ##### Regla Adicional: <br>Sobre un Caballo Pálido
> Las criaturas invocadas por un caballero de la muerte con *encontrar corcel* y *encontrar corcel mayor* son no-muertos, en lugar de uno de los tipos de criaturas listados en esos conjuros.

\pagebreakNum

### Druida

<div class='spellList'>

##### Trucos (Nivel 0)
- Luces Danzantes
- Truco de Druida
- Guía
- ✦ Golpe Lunar
- Salvajismo Primitivo ^XGE^
- Resistencia
- Moldear Agua ^XGE^
- Palo Shillelagh
- ✦ Ira Solar
- Látigo de Espinas

\columnbreak

##### Nivel 1
- Amistad con los Animales
- Vínculo de Bestia ^XGE^
- Curar Heridas
- Detectar Magia
- Detectar Veneno y Enfermedad
- Temblor de Tierra ^XGE^
- Enredar
- Retirada Expeditiva
- Fuego Feérico
- Nube de Niebla
- Baya Mágica
- Palabra Curativa
- Salto
- Pies Ligeros
- Purificar Comida y Bebida
- Sueño
- Trampa ^XGE^
- Hablar con los Animales
- ✦ Fuego Estelar

\columnbreak

##### Nivel 2
- Mensajero Animal
- Piel de Corteza
- Sentido de Bestia
- ✦ Ciclón
- Visión en la Oscuridad
- Diablo de Polvo ^XGE^
- Mejora de Habilidad
- Viento de Gustar
- Sujetar Persona
- Restauración Menor
- Localizar Animales o Plantas
- Rayo de Luna
- Pasar sin Rastro
- Protección contra el Veneno
- Escribir en el Cielo ^XGE^
- Crecimiento de Espinas
- Viento Guardián ^XGE^

\columnbreak

##### Nivel 3
- Sueño Profundo ^XGE^
- Conjurar Animales
- Luz del Día
- Disipar Magia
- Fingir Muerte
- Círculo Mágico
- Palabra Curativa en Masa
- Crecimiento de Plantas
- Protección contra la Energía
- Revivir
- Hablar con las Plantas
- ✦ Oleada Estelar
- Respirar Agua
- Muro de Viento

</div>

\columnbreak

<div class='spellList'>

\columnbreak

##### Nivel 4
- Marchitar
- Encantar Monstruo ^XGE^
- Confusión
- Conjurar Criaturas del Bosque
- Dominar Bestia
- Libertad de Movimiento
- Parra Atrapante
- Guardián de la Naturaleza
- Terreno Alucinatorio
- Localizar Criatura
- ✦ Vórtice de Ursol
- Esfera de Agua ^XGE^

\columnbreak

##### Nivel 5
Despertar
<br> Comunión con la Naturaleza
<br> Controlar Vientos ^XGE^
<br> Amanecer ^XGE^
<br> Sueño
<br> Geas
<br> Restauración Mayor
<br> Curar Heridas en Masa
<br> Adivinación
<br> Caminar por Árboles
<br> Ira de la Naturaleza ^XGE^

\columnbreak

##### Nivel 6
Conjurar Hadas
<br> Bosque Druídico ^XGE^
<br> ✦ Eclipse
<br> Encontrar el Camino
<br> Curar
<br> Inversión de Viento ^XGE^
<br> ✦ Lluvia de Estrellas
<br> Rayo Solar
<br> Transporte a través de Plantas
<br> Muro de Espinas
<br> Andar en el Viento

</div>

<div class='spellList'>

\columnbreak

##### Nivel 7
Corona de Estrellas ^XGE^
<br> Arcano Miraje
<br> Regenerar
<br> Gravedad Invertida
<br> Torbellino ^XGE^

\columnbreak

##### Nivel 8
Formas de Animales
<br> Controlar el Clima
<br> Mente Decrepita
<br> Ráfaga Solar

\columnbreak

##### Nivel 9
Previsión
<br> Curación en Masa
<br> Cambio de Forma
<br> Tormenta de Venganza
<br> Verdadera Resurrección

<div class='footnote'>PARTE 2 | CONJUROS </div>
</div>

\pagebreakNum

### Mago

<div class='spellList'>

##### Trucos (Nivel 0)
- ✦ Explosión Arcana
- Resguardo de Hoja
- Controlar Llamas ^XGE^
- Crear Fogata ^XGE^
- Luces Danzantes
- Proyectil Ígneo
- ✦ Ráfaga
- Mordedura Helada ^XGE^
- Luz
- Mano Mágica
- Reparar
- Mensaje
- Ilusión Menor
- Prestidigitación
- Crear Llama
- Rayo de Escarcha
- Moldear Agua ^XGE^

<div style='margin-top:210px;'></div>

##### Nivel 4
- Ojo Arcano
- ✦ Ampliar o  Disminuir Magia
- ✦ Descarga Arcana
- Destierro
- Encantar Monstruo ^XGE^
- Confusión
- Conjurar Elementales Menores
- Puerta Dimensional
- Escudo de Fuego
- Mensajero Rápido de Galder ^LLK^
- Sumidero Gravitacional ^EGW^
- Invisibilidad Mayor
- Terreno Alucinatorio
- ✦ Bloque de Hielo
- Tormenta de Hielo
- Cofre Secreto de Leomund
- Localizar Criatura
- Santuario Privado de Mordenkainen
- Esfera Resiliente de Otiluke
- Polimorfia
- Invocar Elemental ^TCE^
- Muro de Fuego

\columnbreak

##### Nivel 1
- Alarma
- Armadura de Ágathys
- Manos Ardientes
- Comprender Idiomas
- Crear o Destruir Agua
- Detectar Magia
- Disfrazar
- Retirada Expeditiva
- Caída de Pluma
- Encontrar Familiar
- Dedos de Escarcha ^IDRotF^
- ✦ Proyectil de Fuego y Hielo
- Don de la Alacridad ^EGW^
- Reprensión Infernal
- Cuchillo de Hielo ^XGE^
- Identificar
- Escritura Ilusoria
- Salto
- Pies Ligeros
- Armadura de Mago
- Misil Mágico
- Aumentar Gravedad ^EGW^
- Escudo
- Imagen Silenciosa
- Trampa ^XGE^
- Disco Flotante de Tenser
- Sirviente Invisible

<div style='margin-top:25px;'></div>

##### Nivel 5
- Objetos Animados
- Mano de Bigby
- Cono de Frío
- Conjurar Elemental
- Creación
- Dominar Persona
- Paso Lejano  ^XGE^
- Golpe Ígneo
- Sujetar Monstruo
- Inmolación ^XGE^
- Confusión
- Pasar Muros
- Unión Planar
- Adivinación
- Apariencia
- Empoderar Habilidad ^XGE^
- Estática Sináptica ^XGE^
- Círculo de Teletransporte
- Muro de Fuerza


\columnbreak

##### Nivel 2
- Azotador de Aganazzar ^XGE^
- Alterar Aspecto
- Cerradura Arcana
- Ceguera/Sordera
- Desenfoque
- Nube de Dagas
- Llama Continua
- Oscuridad
- Visión en la Oscuridad
- Detectar Pensamientos
- Aliento de Dragón ^XGE^
- Agrandar/Reducir
- Flechas Ígneas
- Hoja de Llama
- Esfera de Fuego
- Rebaño de Familiares ^LLK^
- Favor de la Fortuna ^EGW^
- Reposo Gentil
- ✦ Toque Helado
- Calentar Metal
- Sujetar Persona
- Objeto Inamovible ^EGW^
- Invisibilidad
- Llamada
- Levitar
- ✦ Bomba Viva
- Localizar Objeto
- Boca Mágica
- Arma Mágica
- Imagen Espejo
- Paso Brumoso
- Aura Mágica de Nystul
- Pasar sin Rastro
- Fuerza Fantasmal
- Pirotecnia ^XGE^
- Trampa de Cuerda
- Rayo Abrasador
- Ver Invisibilidad
- Romper
- Silencio
- Escritura Celeste
- Tormenta de Bolas de Nieve <br/>&nbsp;&nbsp;&nbsp; de Snilloc ^XGE^
- Trepar Paredes
- Sugestión
- Bolsillo de Muñeca ^EGW^

\columnbreak

##### Nivel 3
- ✦ Explosión Arcana
- Parpadeo
- ✦ Ventisca
- Sueño Profundo ^XGE^
- Clarividencia
- Contraconjuro
- Crear Alimento y Agua
- Disipar Magia
- Fingir Muerte
- Bola de Fuego
- Volar
- Torre de Galder ^LLK^
- Glifo de Protección
- Aceleración
- Patrón Hipnótico
- Fortaleza Intelectual ^TCE^
- Círculo Mágico
- Imagen Mayor
- No Detección
- Protección contra la Energía
- Onda de Pulso ^EGW^
- Eliminar Maldición
- Envío
- Tormenta de Granizo
- Lentitud
- ✦ Robar Conjuro
- Ola de Marea ^XGE^
- Sirviente Minúsculo ^XGE^
- Lenguas

##### Nivel 6
- Portal Arcano
- Contingencia
- Desintegrar
- Globo de Invulnerabilidad
- Fisura Gravitacional ^EGW^
- Guardias y Barreras
- Festín de los Héroes
- Investidura de Llama ^XGE^
- Investidura de Hielo ^XGE^
- Sugestión en Masa
- Prisión Mental ^XGE^
- Esfera Helada de Otiluke
- Ilusión Programada
- Dispersar ^XGE^
- Visión Verdadera
- Muro de Hielo
- Palabra de Retorno

</div>

<div class='footnote'>PARTE 2 | CONJUROS </div>

\pagebreakNum

### Mago

<div class='spellList'>

##### Nivel 7
- Bola de Fuego Retrasada
- Etereidad
- Tormenta de Fuego
- Jaula de Fuerza
- Arcano Miraje
- ✦ Pico Glacial
- Mansión Magnífica de Mordenkainen
- Gravedad Invertida
- Imagen Proyectada
- ✦ Piroexplosión
- Segregar
- Teletransporte

\columnbreak

##### Nivel 8
- ✦ Furia de Alexstrasza
- Campo Antimágico
- Clon
- Semiplano
- ✦ Nova de Hielo
- Dragón Ilusorio ^XGE^
- Nube Incendiaria
- Mente en Blanco
- Ruptura de Realidad ^EGW^
- Tsunami

\columnbreak

##### Nivel 9
- Hoja del Desastre ^TCE^
- Previsión
- Portal
- Prisión
- Invulnerabilidad ^XGE^
- ✦ Barco Volador de Jaina
- Polimorfia en Masa ^XGE^
- Muro Prismático
- Lluvia de Meteoros
- Vacío Voraz ^EGW^
- Devastación Temporal ^EGW^
- Detener el Tiempo
- Polimorfia Verdadera

</div>

> ##### Regla Adicional: Magia Arcana
> Esta lista contiene conjuros que no están en línea con la fantasía de Warcraft para los magos, pero que un Dungeon Master aún podría permitir que un mago aprenda. Muchos de estos conjuros están relacionados con la nigromancia o demonología, ambos prohibidos por la mayoría de los cónclaves de magos. Otros son poderosos conjuros de mago sin un equivalente real en el universo de Warcraft.
> <br/>
> <br/>

<div style='column-count:2'>

##### Trucos (Nivel 0)
 Toque Helado
 <br/> ✦ Descomponer
 <br/> Picadura Absorbente ^EGW^
 
<div style='margin-top:165px;'></div> 
 
##### Nivel 4
 Invocar Demonio Mayor ^XGE^
 <br/> Esfera Vitriólica ^XGE^
 
<div style='margin-top:70px;'></div> 
 
##### Nivel 8
 Mente Decrepita
 <br/> Fortaleza Poderosa ^XGE^
 
\columnbreak

##### Nivel 1
 Causar Miedo ^XGE^
 <br/> Falsa Vida
 <br/> Rayo de Enfermedad
 <br/> Sueño
 
<div style='margin-top:150px;'></div> 
 
##### Nivel 5
 Danza Macabra ^XGE^
 
<div style='margin-top:82px;'></div> 
 
##### Nivel 9
 Deseo
 <br/> Sueño del Velo Azul ^TCE^
 
\columnbreak

<div style='margin-top:229px;'></div>

##### Nivel 2
 Rayo de Debilitamiento
 <br/> <br/>

<div style='margin-top:180px;'></div>

##### Nivel 6
 Círculo de Muerte
 <br/> Crear No-Muertos ^XGE^
 <br/> Prohibición
 <br/> <br/>
 
\columnbreak

<div style='margin-top:229px;'></div>

##### Nivel 3
 Animar a los Muertos
 <br/> Bestow Curse
 <br/> Enemigos en Abundancia ^XGE^
 <br/> Miedo
 <br/> Transferencia de Vida ^XGE^
 <br/> Hablar con los Muertos
 <br/> Invocar Demonios Menores ^XGE^
 <br/> Invocar No-Muertos ^TCE^
 <br/> Invocar Sombras ^TCE^
 <br/> Toque Vampírico
 <br/> <br/>
 
##### Nivel 7
 Crear Magen ^IDRotF^
 <br/> Dedo de la Muerte
 <br/> Cambio de Plano
 <br/> <br/> 
</div>

\pagebreakNum



### Paladín

<div class='spellList'>

##### Nivel 1
- Anatema
- Bendición
- Ceremonia ^XGE^
- Comando
- Duelo Compulsivo
- Curar Heridas
- Detectar el Bien y el Mal
- Favor Divino
- Palabra Curativa
- Heroísmo
- Protección contra el Bien y el Mal
- ✦ Arrepentimiento
- Santuario
- Golpe Llameante
- Escudo de Fe
- Golpe Trueno
- Golpe Furioso

##### Nivel 5
- Golpe Desterrador
- Círculo de Poder
- Onda Destructiva
- Disipar el Bien y el Mal
- Santificar
- Arma Sagrada ^XGE^
- ✦ Luz del Protector
- Curar Heridas en Masa
- Resurrección
- Adivinación
- Muro de Luz ^XGE^

\columnbreak

##### Nivel 2
- Ayuda
- Golpe Llameante
- Mejorar Habilidad
- Encontrar Corcel
- Hoja Llameante
- ✦ Guardián del Rey
- ✦ Prisma Sagrado
- Restauración Menor
- Arma Mágica
- Oración de Curación
- Protección contra el Veneno
- ✦ Golpe Justo
- Vínculo Protector
- Zona de Verdad

\columnbreak

##### Nivel 3
- Aura de Vitalidad
- Faro de Esperanza
- ✦ Faro de Luz
- ✦ Luz Cegadora
- Golpe Cegador
- Manto del Cruzado
- Luz del Día
- Disipar Magia
- ✦ Ira Sagrada
- Transferencia de Vida ^XGE^
- Círculo Mágico
- Palabra Curativa en Masa
- Corcel Fantasma
- Protección contra la Energía
- Eliminar Maldición
- Revivir

\columnbreak

##### Nivel 4
- Aura de Vida
- Aura de Pureza
- Protección contra la Muerte
- ✦ Escudo Divino
- Encontrar Corcel Mayor ^XGE^
- Guardián de la Fe
- Localizar Criatura
- Golpe Devastador

</div>


<div class='footnote'>PARTE 2 | CONJUROS </div>

\pagebreakNum

### Sacerdote

<div class='spellList'>

##### Trucos (Nivel 0)
- Guía
- Luz
- Reparar
- ✦ Explosión Mental
- Resistencia
- Llama Sagrada
- Salvar a los Moribundos
- Taumaturgia
- Llamada de la Muerte ^XGE^
- Palabra de Radiancia ^XGE^

<div style='margin-top:250px;'></div>

##### Nivel 4
- Aura de Pureza
- Destierro
- Encantar Monstruo ^XGE^
- Protección contra la Muerte
- ✦ Plaga Devoradora
- Adivinación
- Libertad de Movimiento
- Invisibilidad Mayor
- Guardián de la Fe
- Localizar Criatura
- ✦ Barrera Luminosa
- Asesino Fantasmal
- Lanza Psíquica de Raulothim ^FTD^
- Sombra de Moil ^XGE^
- Radiancia Enferma ^XGE^
- ✦ Apariciones Sombrías
- ✦ Invocar Entidad del Vacío

##### Nivel 7
- Palabra Divina
- Etereidad
- ✦ Halo
- Regenerar
- Resurrección
- Símbolo
- Templo de los Dioses ^XGE^
- Esencia Unida ^EGW^

\columnbreak

##### Nivel 1
- ✦ Pluma Angélica
- Brazos de Hadar
- Bendición
- Causar Miedo ^XGE^
- Ceremonia ^XGE^
- Encantar Persona
- Curar Heridas
- ✦ Vacío Oscuro
- Detectar el Bien y el Mal
- Detectar Magia
- Detectar Veneno y Enfermedad
- Rayo Guiador
- Palabra Curativa
- Heroísmo
- ✦ Fuego Interior
- Infligir Heridas
- ✦ Visión Mental
- Protección contra el Bien y el Mal
- Purificar Comida y Bebida
- Santuario
- Escudo
- Escudo de Fe

##### Nivel 5
- Amanecer ^XGE^
- Disipar el Bien y el Mal
- Dominar Persona
- Geas
- Restauración Mayor
- Santificar
- Leyenda
- Curar Heridas en Masa
- Modificar Memoria
- Inundación de Energía Negativa ^XGE^
- Resurrección
- Vínculo Telepático de Rary
- Adivinación
- ✦ Choque de Sombras
- Empoderar Habilidad ^XGE^
- Estática Sináptica ^XGE^
- Muro de Luz ^XGE^

##### Nivel 8
- Marchitamiento Horrendo de Abi-Dalzim ^XGE^
- Campo Antimágico
- Estrella Oscura ^EGW^
- Dominar Monstruo
- Mente Decrepita
- Aura Sagrada
- Oscuridad Enloquecedora ^XGE^
- Mente en Blanco
- Palabra de Aturdimiento

\columnbreak

##### Nivel 2
- Ayuda
- Ceguera/Sordera
- Calmar Emociones
- Corona de Locura
- ✦ Exorcismo
- ✦ Desvanecerse
- Reposo Gentil
- Don de la Charla ^AI^
- Espíritu Curativo ^XGE^
- Sujetar Persona
- Invisibilidad
- ✦ Enfoque Interior
- ✦ Voluntad Interior
- Restauración Menor
- Levitar
- ✦ Desgarrar Mente
- Aguijón Mental ^XGE^
- Oración de Curación
- Protección contra el Veneno
- ✦ Encadenar No-Muertos
- ✦ Fuerza Brillante
- Silencio
- Sugestión
- Látigo Mental de Tasha ^TCE^

##### Nivel 6
- ✦ Arcángel
- Ojo Maligno
- Encontrar el Camino
- Dañar
- Curar
- ✦ Disipar en Masa
- Sugestión en Masa
- Prisión Mental ^XGE^
- ✦ Escisión
- Visión Verdadera
- Palabra de Retorno

<div style='margin-top:128px;'></div>

##### Nivel 9
- ✦ Apoteosis
- Previsión
- Curación en Masa
- Palabra de Curación
- Palabra de Muerte
- Grito Psíquico ^XGE^
- ✦ Salvación
- Resurrección Verdadera

\columnbreak

##### Nivel 3
- Animar a los Muertos
- Aura de Vitalidad
- Faro de Esperanza
- Bestow Curse
- Luz del Día
- Disipar Magia
- ✦ Estrella Divina
- Enemigos en Abundancia ^XGE^
- Amigos Rápidos ^AI^
- Miedo
- Fingir Muerte
- Forma Gaseosa
- Glifo de Protección
- Hambre de Hadar
- ✦ Nova Sagrada
- Fortaleza Intelectual ^TCE^
- Transferencia de Vida ^XGE^
- Círculo Mágico
- Palabra Curativa en Masa
- Discurso Motivador ^AI^
- Protección contra la Energía
- ✦ Horror Psíquico
- Eliminar Maldición
- Revivir
- Hablar con los Muertos
- Guardianes Espirituales
- Lenguas
- Toque Vampírico
- ✦ Cambio de Vacío

</div>

\pagebreakNum

### Chamán

<div class='spellList'>

##### Trucos (Nivel 0)
- Hoja Retumbante ^SCAG^
- Controlar Llamas ^XGE^
- Crear Fogata ^XGE^
- Proyectil Ígneo
- Mordedura Helada ^XGE^
- Ráfaga ^XGE^
- ✦ Invocar Elementos
- ✦ Descarga de Relámpago
- Llamada de Relámpago ^SCAG^
- Reparar
- Moldear Tierra ^XGE^
- Crear Llama
- Moldear Agua ^XGE^
- Toque Eléctrico
- Retumbo ^XGE^

<div style='margin-top:60px;'></div>

##### Nivel 4
- Conjurar Elementales Menores
- Controlar Agua
- Perdición Elemental ^XGE^
- Libertad de Movimiento
- Localizar Criatura
- Polimorfia
- Moldear Piedra
- Piel de Piedra
- Esfera de Tormenta ^XGE^
- Muro de Fuego
- Esfera Acuática ^XGE^

<div style='margin-top:95px;'></div>

##### Nivel 8
- Campo Antimágico
- ✦ Cataclismo
- Controlar el Clima
- Terremoto
- Tsunami

\columnbreak

##### Nivel 1
- Absorber Elementos ^XGE^
- Crear o Destruir Agua
- Curar Heridas
- Detectar Magia
- Detectar Veneno y Enfermedad
- Temblor de Tierra ^XGE^
- ✦ Choque Elemental
- Nube de Niebla
- ✦ Escudo de Relámpagos
- Golpe Ardiente
- Golpe Trueno
- Ola de Trueno

<div style='margin-top:95px;'></div>

##### Nivel 5
- ✦ Sed de Sangre y Heroísmo
- Comunión con la Naturaleza
- Conjurar Elemental
- Controlar Vientos ^XGE^
- Restauración Mayor
- ✦ Lluvia Curativa
- Leyenda
- Maelstrom ^XGE^
- Curar Heridas en Masa
- ✦ Reencarnación
- Adivinación
- Golpe de Viento de Acero ^XGE^
- Muro de Piedra

<div style='margin-top:43px;'></div>

##### Nivel 9
- Previsión
- Prisión
- Curación en Masa
- Tormenta de Venganza
- Resurrección Verdadera

\columnbreak

##### Nivel 2
- Augurio
- Llama Continua
- Diablo de Polvo ^XGE^
- Ráfaga de Viento
- Espíritu Curativo ^XGE^
- Calentar Metal
- ✦ Erupción de Lava
- Restauración Menor
- Puño Terrestre de Maximiliano ^XGE^
- Protección contra el Veneno
- Romper
- Escritura Celeste ^XGE^
- Viento Guardián ^XGE^

<div style='margin-top:78px;'></div>

##### Nivel 6
- Huesos de la Tierra ^XGE^
- Cadena de Relámpagos
- Carne a Piedra
- Investidura de Piedra ^XGE^
- Investidura de Viento ^XGE^
- Mover Tierra
- Protección Primordial ^XGE^
- Caminar sobre el Viento

\columnbreak

##### Nivel 3
- Llamada de Relámpagos
- ✦ Cadena de Curación
- Contraconjuro
- Disipar Magia
- ✦ Púa Terrestre
- Tierra en Erupción ^XGE^
- Rayo
- Círculo Mágico
- Fundirse en la Piedra
- Protección contra la Energía
- Revivir
- Guardianes Espirituales
- Paso de Trueno ^XGE^
- Ola de Marea ^XGE^
- Muro de Agua ^XGE^
- Respirar Agua
- Caminar sobre el Agua
- Muro de Viento

##### Nivel 7
- Etereidad
- Rociado Prismático
- Regeneración
- Torbellino ^XGE^

\columnbreak

</div>

<div class='footnote'>PARTE 2 | CONJUROS </div>

\pagebreakNum

### Brujo

<div class='spellList'>

##### Trucos (Nivel 0)
- Salpicadura Ácida
- Guardia con Hoja
- Toque Helado
- Crear Fogata ^XGE^
- ✦ Descomponer
- ✦ Diabolismo
- ✦ Llama Vil
- Amigos
- Proyectil Ígneo
- Hoja Verdeante ^TCE^
- Mano de Mago
- Crear Llama
- Picadura Absorbente ^EGW^
- ✦ Rayo Sombrío
- ✦ Deslizamiento Sombrío
- Llamada de la Muerte ^XGE^
- ✦ Toque del Caos

##### Nivel 4
- Ojo Arcano
- Destierro
- Marchitar
- Encantar Monstruo ^XGE^
- Compulsión
- Protección Contra la Muerte
- Tentáculos Negros de Evard
- Encontrar Corcel Mayor ^XGE^
- ✦ Fuego y Azufre
- Invisibilidad Mayor
- Terreno Ilusorio
- Cofre Secreto de Leomund
- Localizar Criatura
- Sabueso de Mordenkainen
- Esfera Resiliente de Otiluke
- Asesino Fantasmal
- Sombra de Moil ^XGE^
- Radiancia Enferma ^XGE^
- Invocar Aberración ^TCE^
- Invocar Demonio Mayor ^XGE^
- Esfera Vitriólica ^XGE^

##### Nivel 8
- Marchitamiento Horrendo de Abi-Dalzim ^XGE^
- Campo Antimágico
- ✦ Cataclismo
- Clonación
- Semiplano
- Dominar Monstruo
- Debilitamiento Mental
- Elocuencia
- Oscuridad Enloquecedora ^XGE^
- Ruptura de la Realidad ^EGW^
- Telepatía

\columnbreak

##### Nivel 1
- Alarma
- Brazos de Hadar
- Maldición
- Causar Miedo ^XGE^
- Orbe Cromático
- Comprender Idiomas
- ✦ Piel Demoníaca
- Detectar Magia
- ✦ Drenar Vida
- Retirada Expeditiva
- Vida Falsa
- Encontrar Familiar
- Réplica Infernal
- Maldición
- Identificar
- Escritura Ilusoria
- Saltar
- Rayo de Enfermedad
- Escudo
- Sueño
- Brebaje Cáustico de Tasha ^TCE^
- Risa Histérica de Tasha
- Siervo Invisible
- Rayo de Bruja

##### Nivel 5
- Concha de Antivida
- ✦ Crear Piedra de Alma
- Danza Macabra ^XGE^
- Disipar el Bien y el Mal
- Dominar Persona
- Energía Enervante ^XGE^
- Paso Lejano ^XGE^
- Geas
- Sujetar Monstruo
- Inmolación ^XGE^
- Plaga de Insectos
- Modificar Memoria
- Inundación de Energía Negativa ^XGE^
- ✦ Lluvia de Fuego
- Vínculo Telepático de Rary
- ✦ Ritual de Invocación
- Adivinación
- Estática Sináptica ^XGE^
- Círculo de Teletransporte
- Muro de Fuerza

##### Nivel 9
- Hoja de Desastre ^TCE^
- Puerta
- Prisión
- Enjambre de Meteoros
- Grito Psíquico ^XGE^
- Vacío Voraz ^EGW^
- Extrañeza

\columnbreak

##### Nivel 2
- Llama de Aganazzar ^XGE^
- Alterar Forma
- Bloqueo Arcano
- Nube de Dagas
- Llama Continua
- ✦ Crear Piedra de Salud
- Corona de Locura
- Oscuridad
- Visión Nocturna
- Aliento del Dragón
- Fascinación
- Encontrar Corcel
- Hoja de Fuego
- Calentar Metal
- Sujetar Persona
- Invisibilidad
- Llamada
- Levitar
- Localizar Objeto
- Flecha Ácida de Melf
- Aguijón Mental ^XGE^
- Paso Sombrío
- Fuerza Fantasmal
- Pirotecnia ^XGE^
- Rayo de Debilitamiento
- Rayo Ardiente
- Hoja Sombría ^XGE^
- Trepar Paredes
- Sugestión
- Látigo Mental de Tasha ^TCE^
- Telaraña

##### Nivel 6
- Portal Arcano
- Círculo de Muerte
- Contingencia
- ✦ Crear Pozo de Almas
- Crear No-Muertos
- Desintegrar
- Invocación Instantánea de Drawmij
- Ojo Maligno
- Globo de Invulnerabilidad
- Dañar
- Investidura de Llama ^XGE^
- Jarra Mágica
- Sugestión en Masa
- Prisión Mental ^XGE^
- Baile Irresistible de Otto
- Aliado Planar
- Dispersar ^XGE^
- ✦ Furia Sombría
- Jaula de Almas ^XGE^
- Invocar Demonio ^TCE^
- Otra Forma Mundana de Tasha ^TCE^
- Verdad
- Palabra de Retiro

\columnbreak

##### Nivel 3
- Bestow Curse
- Clarividencia
- Contraconjuro
- Disipar Magia
- Arma Elemental
- Enemigos en Abundancia ^XGE^
- Miedo
- Volar
- Forma Gaseosa
- Aceleración
- Hambre de Hadar
- Patrón Hipnótico
- Transferencia de Vida ^XGE^
- Imagen Mayor
- Meteoros Menores de Melf
- Corcel Fantasma
- Protección Contra la Energía
- Eliminar Maldición
- Envío
- Hablar con los Muertos
- Invocar Demonios Menores ^XGE^
- Invocar Sombras ^TCE^
- Invocar No-Muertos ^TCE^
- Sirviente Minúsculo ^XGE^
- Lenguas
- Toque Vampírico
- Respirar Agua
- Caminar sobre el Agua

##### Nivel 7
- Explosión Retardada de Bola de Fuego
- Etéreidad
- Dedo de la Muerte
- Tormenta de Fuego
- Jaula de Fuerza
- Espada de Mordenkainen
- Secuestrar
- Teletransportación

> ##### Corcel de Xoroth
> Las criaturas invocadas por un brujo con *encontrar corcel* y *encontrar corcel mayor* son demonios en lugar de otros tipos de criaturas. El conjuro *encontrar corcel mayor* puede invocar un corcel vil además de las otras criaturas enumeradas.

\columnbreak



</div>

<div class='footnote'>PARTE 2 | CONJUROS </div>

\pagebreakNum
> <div style='margin-top:-13px;'></div>
>
> #### Conjuros Nuevos
> <div style='column-count:2; margin-top:3px;'>
> 
> ##### Trucos (Nivel 0)
> Ráfaga Arcana
> <br/> Descomponer
> <br/> Diabolismo
> <br/> Llama Vil
> <br/> Ráfaga
> <br/> Invocar Elementos
> <br/> Rayo de Relámpagos
> <br/> Golpe Lunar
> <br/> Explosión Mental
> <br/> Rayo Sombrío
> <br/> Deslizamiento Sombrío
> <br/> Ira Solar
> <br/> Toque del Caos
> <br>
>
> <br/><div style='margin-top:44px;'></div>
>
> ##### Nivel 2
> Caparazón Antimágico
> <br/> Hervir Sangre
> <br/> Crear Piedra de Salud
> <br/> Ciclón
> <br/> Toque Congelante
> <br/> Bomba Viva
> <br/> Guardián del Rey
> <br/> Prisma Sagrado
> <br/> Estallido Aullador
> <br/> Fortaleza Helada
> <br/> Estallido de Lava
> <br/> Tortura Mental
> <br/> Golpe Justiciero
> <br/> Encadenar No-Muertos
> <br/> Fuerza Resplandeciente
> <br><br>
>
> ##### Nivel 4
> Amplificar o Atenuar Magia
> <br/> Descarga Arcana
> <br/> Conjurar No-Muertos
> <br/> Muerte y Decadencia
> <br/> Escudo Divino
> <br/> Dominar No-Muertos
> <br/> Fuego y Azufre
> <br/> Bloque de Hielo
> <br/> Vórtice de Ursoc
> <br/> Cambio de Vacío
> <br>
>
> <br/><div style='margin-top:75px;'></div>
>
> ##### Nivel 6
> Crear Pozo de Almas
> <br/> Eclipse
> <br/> Furia Sombría
> <br/> Lluvia de Estrellas
> <br><br>
> ##### Nivel 8
> Furia de Alexstraza
> <br/> Cataclismo
> <br/> Nova de Hielo
> 
> \columnbreak
> 
> ##### Nivel 1
> Pluma Angelical
> <br/> Cadenas de Hielo
> <br/> Explosión de Cadáver
> <br/> Vacío Oscuro
> <br/> Agarre Mortal
> <br/> Piel Demoníaca
> <br/> Drenar Vida
> <br/> Favor Temible
> <br/> Choque Elemental
> <br/> Rayo de Escarcha y Fuego
> <br/> Toque Helado
> <br/> Escudo Relámpago
> <br/> Visión Mental
> <br/> Arrepentimiento
> <br/> Fuego Estelar
> <br><br> 
>
> ##### Nivel 3
> Explosión Arcana
> <br/> Asfixiar
> <br/> Faro de Luz
> <br/> Luz Cegadora
> <br/> Tormenta de Nieve
> <br/> Sanación en Cadena
> <br/> Estrella Divina
> <br/> Púa de Tierra
> <br/> Ira Sagrada
> <br/> Manto del Cruzado Caído
> <br/> Robar Conjuro
> <br/> Furia de Estrellas
>
> <br/><div style='margin-top:30px;'></div>
> 
> ##### Nivel 5
> Ejército de los Muertos
> <br/> Sed de Sangre y Heroísmo
> <br/> Crear Piedra de Alma
> <br/> Cadena de Muerte
> <br/> Furia del Dragón de Muerte
> <br/> Lluvia Curativa
> <br/> Luz del Protector
> <br/> Lluvia de Fuego
> <br/> Reencarnación
> <br/> Ritual de Invocación
> <br/> Encadenar No-Muertos
> <br/> Choque Sombrío
> <br/> Fuerza Resplandeciente
> <br/> Arma Profana
> <br><br>
> ##### Nivel 7
> Púa Glacial
> <br/> Piroexplosión
>
> <br/><div style='margin-top:30px;'></div>
> 
> ##### Nivel 9
> Nave Voladora de Jaina
> 
> </div>

<img src='https://www.gmbinder.com/images/72nPPab.jpg' style='position:absolute; top:0px; right:-250px; height:100%' />
<img src='https://www.gmbinder.com/images/9wnUwNO.png' style='position:absolute; top:0px; left:-300px; height:100%; transform:scaleX(-1)' />

<div class='footnote'>PARTE 2 | CONJUROS </div>

\pagebreakNum

## Descripciones de Conjuros
Los nuevos conjuros se presentan en orden alfabético.

#### Furia de Alexstrasza
*Evocación de 8º nivel*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** Personal (cono de 60 pies)
- **Componentes:** V, S
- **Duración:** Instantánea
___
Tus manos se envuelven en llamas mientras proyectas una oleada rugiente de fuego. Cada criatura en un cono de 60 pies debe hacer una tirada de salvación de Constitución. Si falla, el objetivo sufre 12d6 de daño por fuego y queda aturdido hasta el final de su próximo turno. Si tiene éxito, el objetivo sufre la mitad de daño y no queda aturdido. El fuego se extiende alrededor de las esquinas y enciende objetos inflamables que no estén siendo llevados o usados. Una criatura que muere por este conjuro queda reducida a cenizas.

#### Amplificar o Atenuar Magia
*Abjuración de 4º nivel*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** Toque
- **Componentes:** S, M (un objeto de valor para la criatura)
- **Duración:** Concentración, hasta 1 minuto
___
Manipulas el flujo de maná que atraviesa a una criatura. Si la criatura no está dispuesta, debes realizar un ataque de conjuro cuerpo a cuerpo para manipular su flujo. Al tocar a la criatura, eliges un efecto para aplicarle durante la duración del conjuro.

***Amplificar.*** Amplificas el poder mágico de la criatura. La criatura inflige daño adicional con sus conjuros, recibe daño adicional de los conjuros y restaura puntos de golpe adicionales con conjuros en una cantidad igual a tu modificador de conjuro.

***Atenuar.*** Atenúas el poder mágico de la criatura. La criatura reduce el daño que recibe de conjuros, el daño que inflige con ellos y la cantidad de puntos de golpe restaurados por conjuros en una cantidad igual a tu modificador de conjuro.

#### Pluma Angelical
*Encantamiento de 2º nivel*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** Toque
- **Componentes:** V, S, M (una pluma)
- **Duración:** Concentración, hasta 1 minuto
___
Tocas a una criatura dentro de tu alcance, otorgándole la rapidez de un ser angelical. Durante la duración del conjuro, la criatura puede usar las acciones de Correr y Retirarse como acción adicional en su turno y gana resistencia al daño por caída.

\columnbreak

#### Apoteosis
*Transmutación de 9º nivel*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** Personal
- **Componentes:** V, S
- **Duración:** Concentración, hasta 10 minutos
___
Adquieres una forma sagrada, emitiendo luz brillante en un radio de 40 pies y luz tenue en 40 pies adicionales. Hasta que el conjuro termine, obtienes los siguientes beneficios:

* Eres inmune al daño radiante y tienes resistencia al daño necrótico.
* Los aberrantes, elementales, fatas, demonios y no muertos tienen desventaja en las tiradas de ataque contra ti.
* Obtienes una velocidad de vuelo de 60 pies gracias a unas alas espectrales.
* Una criatura que se mueva a 10 pies de ti por primera vez en un turno o termine su turno allí sufre 2d10 de daño radiante y debe realizar una tirada de salvación de Constitución o quedar cegada hasta el final de tu próximo turno.
* Puedes usar tu acción para crear una línea de radiancia sagrada de 30 pies de largo y 10 pies de ancho. Cada criatura en la línea debe hacer una tirada de salvación de Constitución. Si falla, sufre 8d8 de daño radiante y queda cegada hasta el final de tu próximo turno. Si tiene éxito, sufre la mitad de daño.
* Puedes usar una acción para tocar a una criatura con luz sanadora. La criatura recupera 8d8 puntos de golpe.

#### Descarga Arcana
*Evocación de 4º nivel*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** 120 pies
- **Componentes:** V, S
- **Duración:** Instantánea
___
Manifiestas tres proyectiles de energía pura y los lanzas hacia un objetivo dentro del alcance. Realiza un ataque de conjuro a distancia por cada proyectil. Si impacta, el objetivo sufre 5d4 de daño de fuerza y es empujado 10 pies directamente lejos de ti.

***A niveles superiores.*** Cuando lanzas este conjuro usando una ranura de conjuro de 5º nivel o superior, crea un proyectil adicional por cada nivel por encima del 4º.

#### Ráfaga Arcana
*Truco de evocación*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** 60 pies
- **Componentes:** V, S
- **Duración:** Instantánea
___
Extiendes tu mano y haces que una explosión de energía arcana estalle desde un objetivo dentro del alcance. Si el objetivo es una criatura, debe realizar una tirada de salvación de Destreza o sufre 1d8 de daño de fuerza. Si una criatura debe hacer una tirada de salvación de Constitución para mantener la concentración debido a este conjuro, la hace con desventaja.

El daño de este conjuro aumenta en 1d8 cuando alcanzas el nivel 5 (2d8), el nivel 11 (3d8) y el nivel 17 (4d8).

<div class='footnote'>PARTE 2 | CONJUROS </div>

\pagebreakNum

#### Explosión Arcana
*Evocación de nivel 3*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** Uno mismo (esfera de 3 metros de radio)
- **Componentes:** V, S
- **Duración:** Instantánea
___
Extraes poder arcano fluctuante y lo liberas en una onda de energía. Cada criatura en el área debe hacer una tirada de salvación de Destreza. Con una salvación fallida, el objetivo sufre 6d8 de daño de fuerza y no puede tomar reacciones hasta el inicio de su próximo turno. Si tiene éxito, el objetivo recibe la mitad de daño y puede usar sus reacciones normalmente.

***A niveles superiores.*** Cuando lanzas este hechizo con un espacio de conjuro de nivel 4 o superior, el daño aumenta en 1d8 por cada nivel de espacio por encima del 3.

\columnbreak

#### Arcángel
*Transmutación de nivel 6*
___
- **Tiempo de lanzamiento:** 1 acción adicional
- **Alcance:** Uno mismo
- **Componentes:** V, S, M (un objeto con un símbolo de Luz o Sombra, valorado en al menos 500 po)
- **Duración:** Concentración, hasta 1 minuto
___
Pronuncias una oración invocando los poderes de la Luz o la Sombra para apoyar tu causa. Obtienes los siguientes beneficios mientras dure el hechizo:
* Eres inmune al daño por fuego y radiante (Luz) o psíquico y necrótico (Sombra).
* Eres inmune a la condición de encantado (Luz) o asustado (Sombra).
* Crecen alas espectrales, otorgándote una velocidad de vuelo de 12 metros.
* Puedes añadir tu modificador de conjuro a los hechizos que restauran puntos de golpe (Luz) o infligen daño (Sombra). El sacerdote también recupera puntos de golpe iguales a la mitad del daño o curación hechos a un objetivo del conjuro.
* Puedes lanzar trucos que normalmente requieren 1 acción como acción adicional.

___
___
> ## Horda Tambaleante
>*Horda Gargantuesca de no muertos Medianos, maligna caótica*
> ___
> - **Clase de Armadura** 8
> - **Puntos de Golpe** 145 (10d20 + 40)
> - **Velocidad** 6 m.
>___
>|FUE|DES|CON|INT|SAB|CAR|
>|:---:|:---:|:---:|:---:|:---:|:---:|
>|25 (+7)|6 (-2)|18 (+4)|3 (-4)|6 (-2)|5 (-3)|
>___
> - **Tiradas de Salvación** Sab +2
> - **Inmunidad al Daño** veneno
> - **Inmunidad a Condiciones** cegado, encantado, ensordecido, agotado, asustado, apresado, incapacitado, paralizado, petrificado, envenenado, boca abajo, restringido, aturdido, inconsciente
> - **Sentidos** visión en la oscuridad 18 m., percepción pasiva 8
> - **Idiomas** —
> - **Desafío** 8 (3,900 PX)
> ___
> ***Compulsión Devoradora.*** La horda puede compartir el espacio con otra criatura. Si una criatura que no sea un no muerto o constructo comparte el espacio con la horda al inicio del turno de esta, la horda queda incapacitada (ignorando su inmunidad a esta condición) y la criatura queda engullida. Mientras está engullida, la criatura está restringida y recibe 21 (6d6) de daño perforante al inicio de cada turno de la horda, o 10 (3d6) si la horda tiene la mitad o menos de sus puntos de golpe. La criatura debe superar una salvación de Constitución CD 15 o infectarse con la enfermedad de la muerte tambaleante.
>
> \columnbreak
>
> <br>&nbsp;&nbsp; Una criatura enferma no puede recuperar puntos de golpe hasta que la enfermedad sea curada. Por cada 24 horas que transcurran, debe repetir la salvación, reduciendo su máximo de puntos de golpe en 10 (3d6) si falla. La criatura muere si su máximo se reduce a 0. Esta reducción permanece hasta que la enfermedad sea curada.
<br>&nbsp;&nbsp; Las criaturas engullidas pueden intentar escapar haciendo una prueba de Fuerza CD 18 como acción. Si tiene éxito, escapa y se mueve a un espacio a 1,5 metros de la horda.
>
> ***Horda.*** La horda puede ocupar el espacio de una criatura Grande o menor y viceversa, y puede moverse por cualquier apertura suficientemente grande para un zombi Mediano. La horda no puede recuperar ni ganar puntos de golpe temporales.
>
> ***Fortaleza de los No Muertos.*** Si recibe daño, debe hacer una tirada de salvación de Constitución con una CD de 5 + el daño recibido, a menos que sea daño radiante o un golpe crítico. Si tiene éxito, no recibe daño.
>
> ### Acciones
> ***Multiataque.*** La horda puede realizar hasta tres ataques de Golpe, y cada uno debe dirigirse a un objetivo diferente.
>
> ***Golpes.*** *Ataque cuerpo a cuerpo con arma:* +10 para golpear, alcance 1,5 m., un objetivo. *Impacto:* 21 (6d6) de daño contundente, o 10 (3d6) si la horda tiene la mitad o menos de sus puntos de golpe. Si el objetivo es Grande o menor, queda apresado (escapar CD 18).

<div class='footnote'>PARTE 2 | HECHIZOS</div>

\pagebreakNum

#### Ejército de los Muertos
*Nigromancia de nivel 5*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** Uno mismo
- **Componentes:** V, S, M (masa cerebral de un humanoide asesinado en las últimas 24 horas)
- **Duración:** Concentración, hasta 1 minuto
___
Pronuncias palabras profanas y convocas un ejército de muertos para destruir y consumir todo a su paso. Una horda de cadáveres tambaleantes aparece a tu alrededor y desaparece cuando sus puntos de golpe llegan a 0 o cuando el hechizo termina.

Tira iniciativa por la horda, que tiene sus propios turnos. No puedes controlar a la horda. En sus turnos, persigue y ataca al ser no muerto más cercano con todas sus capacidades. <br> Usará su acción de Golpes para atacar y apresar a criaturas antes de ocupar sus espacios y engullirlas en el siguiente turno usando su habilidad de Compulsión Devoradora. Si no hay criaturas al alcance, usará todo su movimiento para acercarse a cualquier ser no muerto que pueda ver o escuchar. Si no hay criaturas evidentes, te seguirá sin sentido hasta que aparezcan objetivos.

Cuando lanzas este hechizo, puedes designar cualquier cantidad de criaturas visibles para que la horda las ignore y no se vean afectadas por su Compulsión Devoradora. Si dejas de concentrarte antes de que el hechizo termine, la horda permanecerá durante 1d6 asaltos si aún tiene puntos de golpe y ya no ignorará a esas criaturas.

#### Asfixiar
*Nigromancia de nivel 3*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** 9 metros
- **Componentes:** S
- **Duración:** Concentración, hasta 1 minuto
___
Tentáculos sombríos emergen y rodean la garganta de una criatura que puedes ver dentro del alcance. El objetivo debe hacer una tirada de salvación de Constitución exitosa o quedará inmovilizado e incapacitado mientras dure el hechizo. Mientras esté inmovilizado de esta forma, no puede hablar. Al final de cada uno de sus turnos, el objetivo puede repetir la tirada de salvación de Constitución. Con éxito, el hechizo termina.

#### Faro de Luz
*Evocación de nivel 3*
___
- **Tiempo de lanzamiento:** 1 acción adicional
- **Alcance:** 18 metros
- **Componentes:** V, S
- **Duración:** Concentración, hasta 10 minutos
___
Extiendes tu mano y marcas con una luz sagrada a una criatura dentro del alcance. Siempre que restaures puntos de golpe con un espacio de conjuro, la criatura marcada recupera un número de puntos igual a tu modificador de conjuro. El hechizo termina si la criatura sale del alcance del hechizo.

\columnbreak

#### Luz Cegadora
*Evocación de nivel 3*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** Uno mismo (radio de 9 metros)
- **Componentes:** V, S
- **Duración:** Instantánea
___
Provocas que una luz deslumbrante estalle a tu alrededor. Cada criatura en un radio de 9 metros debe superar una tirada de salvación de Constitución o quedará cegada durante 1 minuto o hasta que reciba daño.

Una criatura cegada por este hechizo puede repetir la tirada de salvación de Constitución al final de cada uno de sus turnos. Si tiene éxito, deja de estar cegada.

#### Ventisca
*Evocación de nivel 3*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** 36 metros
- **Componentes:** V, S, M (fragmentos de vidrio)
- **Duración:** Concentración, hasta 1 minuto
___
Una luz fría emana de tu mano al cielo mientras fragmentos azules caen en un cilindro de 6 metros de radio y 12 metros de altura centrado en un punto dentro del alcance. Hasta que el hechizo termine, fragmentos de hielo caen sobre la zona.
Cuando una criatura entra en el área por primera vez en un turno o comienza su turno allí, debe hacer una tirada de salvación de Destreza. Si falla, recibe 3d6 de daño por frío o la mitad si tiene éxito.

***A niveles superiores.*** Cuando lanzas este hechizo con un espacio de nivel 4 o superior, el daño aumenta en 1d6 por cada nivel de espacio por encima del 3.

#### Hervor de Sangre
*Nigromancia de nivel 2*
___
- **Tiempo de lanzamiento:** 1 acción adicional
- **Alcance:** Uno mismo (radio de 4,5 metros)
- **Componentes:** V, S
- **Duración:** Instantánea
___
Extiendes tu poder profano, haciendo que la sangre en las venas de las criaturas cercanas hierva. Cada criatura que elijas en un radio de 4,5 metros debe superar una tirada de salvación de Constitución o recibe 2d4 de daño por fuego más 2d4 de daño necrótico. <br> Las criaturas que tengan éxito en su tirada de salvación reciben la mitad de daño. Las criaturas que no tengan sangre o fluidos vitales son inmunes a este hechizo.

***A niveles superiores.*** Cuando lanzas este hechizo con un espacio de nivel 3 o superior, el daño por fuego y necrótico aumenta en 1d4 por cada nivel de espacio por encima del 2.

<div class='footnote'>PARTE 2 | HECHIZOS</div>

\pagebreakNum

#### Sed de Sangre y Heroísmo
*Encantamiento de nivel 5*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** Uno mismo (radio de 9 metros)
- **Componentes:** V, S
- **Duración:** Concentración, hasta 1 minuto
___
Infundes a las criaturas que elijas dentro del alcance con determinación para luchar con mayor fuerza. Cada objetivo obtiene los siguientes beneficios durante la duración del hechizo:

- El objetivo es inmune al estado de asustado y cualquier condición de asustado sobre él se suprime mientras dure el hechizo.
- Siempre que el objetivo realice una tirada de ataque o salvación antes de que el hechizo termine, puede lanzar 1d4 y sumar el resultado a la tirada de ataque o salvación.
- El objetivo obtiene puntos de golpe temporales igual a tu modificador de conjuro al inicio de cada uno de sus turnos. Cuando el hechizo termine, pierde cualquier punto de golpe temporal que le quede de este hechizo.

#### Cataclismo
*Conjuración de nivel 8*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** 45 metros
- **Componentes:** V, S, M (un trozo de carbón)
- **Duración:** Instantánea
___
Haces que el suelo se resquebraje y se abra, liberando magma y fuego en un radio de 18 metros centrado en un punto dentro del alcance. Cada criatura en la zona debe hacer una tirada de salvación de Destreza o recibirá 10d6 de daño por fuego, o la mitad de daño si tiene éxito.

Las criaturas que sufran daño inicial por fuego quedan envueltas en llamas, recibiendo 2d6 de daño por fuego al inicio de cada uno de sus turnos. Pueden usar su acción o un aliado adyacente para apagar las llamas, recibiendo 1d6 de daño por el proceso.

El terreno en la zona permanece dañado, convirtiéndose en terreno difícil. Permanece caliente durante 1 minuto, y cualquier criatura que entre por primera vez o comience su turno en esta zona recibe 1d6 de daño por fuego.

#### Sanación en Cadena
*Evocación de nivel 3*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** 9 metros (4,5 metros entre objetivos)
- **Componentes:** V, S
- **Duración:** Instantánea
___
Un rayo de energías restauradoras atraviesa a criaturas aliadas. Elige un objetivo que puedas ver dentro del alcance, luego otro objetivo que esté dentro del alcance del primero, y así sucesivamente hasta tres. No puedes elegir el mismo objetivo más de una vez. Cada objetivo recupera un número de puntos de golpe igual a 2d4 + tu modificador de conjuro. Este hechizo no tiene efecto en no muertos ni constructos.

***A niveles superiores.*** Al lanzarlo con un espacio de conjuro de nivel 4 o superior, la sanación alcanza un objetivo adicional por cada nivel de espacio por encima del 3.

\columnbreak

#### Cadenas de Hielo
*Evocación de nivel 1*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** 18 metros
- **Componentes:** V
- **Duración:** 1 minuto
___
Cadenas heladas emergen del suelo bajo un objetivo que puedes ver dentro del alcance. El objetivo debe superar una tirada de salvación de Fuerza o su velocidad se verá reducida a la mitad durante la duración del hechizo.

El objetivo encadenado debe hacer una tirada de salvación de Fuerza al final de cada uno de sus turnos. Si tiene éxito, las cadenas se rompen y el hechizo termina.

***A niveles superiores.*** Al lanzarlo con un espacio de nivel 2 o superior, puedes seleccionar un objetivo adicional por cada nivel de espacio por encima del 1.

#### Invocar No Muerto
*Conjuración de nivel 4*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** 18 metros
- **Componentes:** V, S, M (vísceras de una criatura muerta <br> en las últimas 24 horas)
- **Duración:** Concentración, hasta 1 hora
___
Invocas a un poderoso no muerto desde las criptas o mataderos de Rasganorte. Eliges el tipo de no muerto, que debe tener un nivel de desafío 5 o menor, como un revenant o espectro. Aparece en un espacio desocupado que puedas ver dentro del alcance y desaparece cuando sus puntos de golpe lleguen a 0 o el hechizo termine.

Tira iniciativa para el no muerto, que tiene sus propios turnos. Cuando lo invocas y en cada uno de tus turnos, puedes darle una orden verbal (sin requerir acción) para que actúe en su próximo turno. Si no das órdenes, atacará a cualquier criatura que haya atacado en su alcance.

Si dejas de concentrarte antes de que termine la duración, el no muerto pasará el resto de la duración atacando al ser vivo más cercano.

***A niveles superiores.*** Al lanzarlo con un espacio de nivel 5 o superior, el nivel de desafío aumenta en 1 por cada nivel de espacio por encima del 4.

<div class='footnote'>PARTE 2 | HECHIZOS</div>

\pagebreakNum

#### Explosión de Cadáver
*Nigromancia de nivel 1*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** 36 metros
- **Componentes:** S, M (un cadáver, que el hechizo destruye)
- **Duración:** Instantánea
___
El cadáver de una criatura recientemente fallecida se hincha rápidamente bajo tu comando y estalla en una explosión macabra. Apunta al cadáver de una criatura que haya muerto hace no más de 1 minuto y que puedas ver dentro del alcance. Cada criatura a 1,5 metros del cadáver debe hacer una tirada de salvación de Destreza. Un objetivo sufre 2d6 de daño necrótico si falla, o la mitad de daño si tiene éxito. El radio de la explosión aumenta en 1,5 metros por cada categoría de tamaño del cadáver superior a Mediano.

Un cadáver detonado de esta manera se destruye y no puede ser resucitado mediante habilidades que requieran un cadáver completo. No todas las criaturas dejan un cadáver; los constructos y limos casi nunca lo hacen, tampoco los no muertos incorpóreos.

***A niveles superiores.*** Cuando lanzas este hechizo con un espacio de nivel 2 o superior, el daño aumenta en 2d6 por cada nivel de espacio por encima del 1.

#### Crear Piedra de Salud
*Conjuración de nivel 2*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** Toque
- **Componentes:** V, S
- **Duración:** Instantánea
___
Creas una piedra verde resplandeciente del tamaño de un puño en tu mano. Una criatura puede usar su acción para aplastar la piedra, destruyéndola y recuperando puntos de golpe iguales a 1d10 + tu modificador de conjuro. La piedra pierde su poder si no se usa dentro de 24 horas.

**A niveles superiores.** Al lanzarlo con un espacio de nivel 3 o superior, la curación aumenta en 1d10 por cada nivel de espacio por encima del 2.

#### Crear Piedra de Alma
*Conjuración de nivel 5 (ritual)*
___
- **Tiempo de lanzamiento:** 10 minutos
- **Alcance:** Uno mismo (radio de 9 metros)
- **Componentes:** V, S, M (un orbe de cristal valorado en 50 po)
- **Duración:** 10 días
___
Vinculas las almas de criaturas al mundo de los vivos, permitiendo que regresen de la muerte. Al lanzar este hechizo, selecciona hasta seis criaturas dispuestas dentro del alcance. Si alguna de ellas llega a 0 puntos de golpe durante la duración, quedará con 1 punto de golpe en su lugar y el componente material se consume. Al terminar el hechizo, cada criatura que haya sido salvada será notificada de que el hechizo ha concluido y qué criatura fue protegida. No puede alertar ni salvar a criaturas en otro plano de existencia.

Si lanzas este hechizo de nuevo, el efecto de cualquier piedra de alma creada anteriormente termina. El hechizo también termina si el componente material deja de estar contigo. Una criatura solo puede beneficiarse de una piedra de alma a la vez.

\columnbreak

#### Crear Pozo de Almas
*Conjuración de nivel 6*
___
- **Tiempo de lanzamiento:** 10 minutos
- **Alcance:** 1,5 metros
- **Componentes:** V, S
- **Duración:** 1 minuto
___
Haces aparecer un altar rúnico de piedra en un espacio desocupado dentro del alcance. Una criatura aliada puede usar su acción para sumergir su mano en el líquido que llena el altar y extraer una piedra verde resplandeciente. Cuando el hechizo termina, el altar desaparece, pero las piedras permanecen hasta ser usadas o hasta 24 horas después, lo que ocurra primero. Una criatura puede aplastar la piedra como acción para recuperar puntos de golpe iguales a 4d10 + tu modificador de conjuro.

**A niveles superiores.** Cuando lanzas este hechizo con un espacio de nivel 7 o superior, la curación aumenta en 1d10 por cada nivel de espacio por encima del 6.

#### Ciclón
*Conjuración de nivel 2*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** 18 metros
- **Componentes:** V, S
- **Duración:** Concentración, hasta 1 minuto
___
Un remolino de viento envuelve a una criatura Grande o más pequeña que puedas ver dentro del alcance. El objetivo debe hacer una tirada de salvación de Fuerza. Si falla, es levantado del suelo y queda inmovilizado mientras dure el hechizo.

Como acción, puedes mover el ciclón hasta 6 metros en una dirección de tu elección. Una criatura inmovilizada por el ciclón se moverá con él. Si el ciclón atraviesa un espacio demasiado estrecho para la criatura inmovilizada, esta se libera y el hechizo termina.

Para liberarse, el objetivo puede usar su acción para hacer una prueba de Fuerza contra la CD de salvación de tu hechizo. Si tiene éxito, escapa y deja de estar inmovilizado. El ciclón desaparece entonces.

#### Vacío Oscuro
*Evocación de nivel 1*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** 9 metros
- **Componentes:** V, S, M (un símbolo sagrado)
- **Duración:** Instantánea
___
Tiras del velo que separa la realidad del reino del vacío, creando pequeñas fisuras por donde se filtran energías perturbadoras. Una criatura dentro del alcance y otras criaturas de tu elección a 1,5 metros de ella deben superar una tirada de salvación de Sabiduría o sufrirán 2d4 de daño psíquico si fallan, o la mitad de daño si tienen éxito. Las criaturas que fallen tampoco podrán recuperar puntos de golpe durante 1 asalto.

***A niveles superiores.*** Cuando lanzas este hechizo con un espacio de nivel 2 o superior, el daño aumenta en 1d4 por cada nivel de espacio por encima del 1.

<div class='footnote'>PARTE 2 | HECHIZOS</div>

\pagebreakNum

#### Muerte y Decadencia
*Nigromancia de nivel 4*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** 18 metros
- **Componentes:** V, S
- **Duración:** Concentración, hasta 1 minuto
___
Apuntas a un punto que puedas ver dentro del alcance, creando una esfera de 6 metros de radio llena de energía necrótica que marchita y descompone todo a su paso. Cuando una criatura entra por primera vez en el área o comienza su turno allí, debe hacer una tirada de salvación de Constitución. Si falla, recibe 4d8 de daño necrótico y resta 1d4 de todas sus tiradas de ataque y salvación hasta el inicio de su próximo turno, como si estuviera bajo el efecto del hechizo perdición. Si tiene éxito, sufre la mitad de daño y no sufre efectos adicionales.

Los no muertos en el área no reciben daño y son fortalecidos por el poder necrótico, sumando 1d4 a sus tiradas de ataque y salvación, como si estuvieran bajo el efecto de un hechizo bendición.

***A niveles superiores.*** Cuando lanzas este hechizo con un espacio de nivel 5 o superior, el daño aumenta en 1d8 por cada nivel de espacio por encima del 4.

#### Cadena de Muerte
*Nigromancia de nivel 5*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** Uno mismo (radio de 6 metros)
- **Componentes:** V, S
- **Duración:** Concentración, hasta 1 minuto
___
Cadenas espectrales surgen hacia hasta tres criaturas diferentes que puedas ver dentro del alcance. Realiza un ataque de conjuro a distancia contra cada objetivo. Si aciertas, el objetivo recibe 4d8 de daño necrótico y queda encadenado a ti y a cualquier otro objetivo afectado por la duración del hechizo.

Las criaturas encadenadas deben superar una tirada de salvación de Fuerza para alejarse más de 6 metros de ti. Si tienen éxito, rompen la cadena, terminando el efecto sobre ellas. Cuando tú o cualquier criatura encadenada reciban daño de un ataque o hechizo, las demás criaturas encadenadas (incluyéndote) reciben daño psíquico igual a la mitad del daño recibido.

El daño que recibas por este hechizo no provoca tiradas de salvación de Constitución para mantener la concentración.

#### Agarre de la Muerte
*Evocación de nivel 1*
___
- **Tiempo de lanzamiento:** 1 acción adicional
- **Alcance:** 18 metros
- **Componentes:** V, S
- **Duración:** Instantánea
___
Energía necrótica envuelve a una criatura Grande o más pequeña que puedas ver y que esté al menos a 3 metros de distancia de ti, dentro del alcance del hechizo. La criatura debe hacer una tirada de salvación de Fuerza exitosa o será movida a un espacio vacío a 1,5 metros de ti, y tu siguiente tirada de ataque contra ella en este turno tendrá ventaja.

\columnbreak

#### Furia del Dragón de la Muerte
*Conjuración de nivel 5*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** Uno mismo
- **Componentes:** V, S, M (una escama de un dragón muerto)
- **Duración:** Instantánea
___
Invocas a un poderoso dragón no muerto que desata destrucción sobre tus enemigos. Elige invocar un draco-ascua, draco-escarcha o draco-vil. Aparece flotando sobre ti y usa su arma de aliento, imbuida con poder necrótico, antes de desaparecer.

El hechizo falla si no hay espacio suficiente para que el dragón aparezca (por ejemplo, en un túnel estrecho). Los dragones vivos que te vean lanzar este hechizo te considerarán un enemigo jurado si aún no lo eran.

***Draco-Ascua.*** El dragón exhala fuego en un cono de 18 metros. Cada criatura en el área debe hacer una tirada de salvación de Destreza, recibiendo 5d8 de daño por fuego y 5d8 de daño necrótico si falla, o la mitad si tiene éxito.

***Draco-Escarcha.*** El dragón exhala una ráfaga helada en un punto dentro de 36 metros. Cada criatura en un radio de 6 metros debe hacer una tirada de salvación de Destreza, recibiendo 5d8 de daño por frío y 5d8 de daño necrótico si falla, o la mitad si tiene éxito.

***Draco-Vil*** El dragón exhala ácido en una línea de 36 metros <br> de largo y 3 metros de ancho. Cada criatura en la línea debe hacer una tirada de salvación de Destreza, recibiendo 5d8 de daño por ácido y 5d8 de daño necrótico si falla, o la mitad si tiene éxito.

#### Descomposición
*Truco de nigromancia*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** Toque
- **Componentes:** V, S
- **Duración:** 1 minuto
___
Tocas el cadáver de una criatura. En el transcurso de un minuto, el cadáver comienza a descomponerse rápidamente, brotando hongos y musgo mientras se degrada en abono y mantillo. Una o dos flores de colores inusuales también pueden brotar del cadáver en este tiempo. Los requisitos aplicables para la resurrección no se ven afectados por esta descomposición.

<div class='footnote'>PARTE 2 | HECHIZOS</div>

\pagebreakNum

#### Piel Demoníaca
*Transmutación de nivel 1*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** Uno mismo
- **Componentes:** V, S, M (piel seca de un demonio o engendro)
- **Duración:** 8 horas
___
Tu piel se cubre de una capa de energía vil, infundiéndote con vigor demoníaco. Tu Clase de Armadura base se convierte en 8 + tu modificador de conjuro (CA mínima de 10).

Además, tus puntos de golpe actuales y tu máximo de puntos de golpe aumentan en 2. Si al finalizar el hechizo tus puntos de golpe actuales caen a 0 o menos, quedas a 1 punto de golpe en su lugar.

***A niveles superiores.*** Cuando lanzas este hechizo con un espacio de nivel 2 o superior, la CA otorgada aumenta en 1 y tus puntos de golpe actuales y tu máximo de puntos de golpe aumentan en 2 por cada nivel de espacio por encima del 1.

#### Plaga Devoradora
*Nigromancia de nivel 4*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** 18 metros
- **Componentes:** V, S, M (una gota de médula ósea)
- **Duración:** 1 minuto
___
Elige una criatura que puedas ver dentro del alcance. El objetivo debe superar una tirada de salvación de Constitución o se verá afectado por una enfermedad horrible durante la duración del hechizo. Hasta que termine el hechizo, siempre que golpees a la criatura afectada o falle una tirada de salvación contra tu hechizo, recibirá 2d8 de daño necrótico.

Además, si la criatura afectada es reducida a 0 puntos de golpe, puedes gastar y lanzar dos de tus Dados de Golpe no utilizados para recuperar puntos de golpe iguales al resultado más tu modificador de conjuro.

Dado que este hechizo induce una enfermedad natural, cualquier efecto que elimine o reduzca los efectos de una enfermedad puede aplicarse.

**A niveles superiores.** Cuando se lanza con un espacio de nivel 3 o superior, el daño necrótico aumenta en 1d8, y el número de Dados de Golpe que pueden gastarse y añadirse a la curación aumenta en uno por cada nivel de espacio por encima del 2.

\columnbreak

#### Diabolismo
*Truco de nigromancia*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** Uno mismo
- **Componentes:** S
- **Duración:** Hasta 1 hora
___
Este hechizo canaliza una pequeña cantidad de energía oscura. Creas uno de los siguientes efectos mágicos dentro del alcance:
- Elige un punto dentro de 9 metros. En un radio de 1,5 metros de ese punto, la luz brillante se vuelve tenue y la luz tenue se convierte en oscuridad durante 1 hora. Cualquier fuente de luz en el área ve su luz suprimida.
- Un objeto de hasta 30 cm cúbicos o un área de hasta 30 cm cuadrados que toques se descompone ligeramente. La madera se pudre, el vidrio se agrieta, las flores se marchitan. Si continúas tocándolo por 1 minuto, el objetivo se destruye. Este hechizo no afecta criaturas, objetos mágicos o materiales resistentes como el metal y la piedra.
- Puedes reanimar una bestia Tiny de CR 0 durante 1 hora. Es un no muerto que obedece tus órdenes, aunque no puede atacar. No puedes usar este efecto hasta que la criatura reanimada muera o el efecto termine.
- Enciendes instantáneamente una vela, antorcha o fogata. El fuego brilla en rojo, verde brillante o púrpura sombrío, a tu elección, hasta que se extinga.
- La punta de tu dedo brilla en verde o púrpura hasta 1 minuto. Mientras brilla, puedes usarlo para dibujar líneas luminosas en una superficie sólida, que duran 1 hora.

Puedes tener hasta tres efectos no instantáneos activos a la vez al lanzar este hechizo varias veces, y puedes disipar un efecto como acción.

#### Estrella Divina
*Evocación de nivel 3*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** Uno mismo (línea de 9 metros)
- **Componentes:** V, S
- **Duración:** Instantánea
___
Una estrella de energía divina avanza en una línea de 9 metros de largo y 1,5 metros de ancho desde ti en una dirección de tu elección. Cada criatura aliada en el camino de la estrella recupera 2d8 puntos de golpe, y cada criatura hostil debe hacer una tirada de salvación de Destreza, recibiendo 3d8 de daño radiante si falla o la mitad si tiene éxito.

**A niveles superiores.** Cuando lanzas este hechizo con un espacio de nivel 4 o superior, la curación y el daño del hechizo aumentan en 1d8 por cada nivel de espacio por encima del 3.

\pagebreakNum

#### Escudo Divino
*Abjuración de nivel 4*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** Uno mismo
- **Componentes:** V, S, M (un pequeño espejo de plata)
- **Duración:** Concentración, hasta 1 minuto
___
Una barrera de energía divina te envuelve, protegiéndote contra ataques. Durante la duración, eres inmune al daño causado por ataques de armas, hechizos y efectos similares. El hechizo no te protege de fuentes de daño natural, como lava o caídas.

Si realizas un ataque o lanzas un hechizo que afecta a una criatura enemiga, este hechizo termina.

#### Dominar No Muerto
*Encantamiento de nivel 4*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** 18 metros
- **Componentes:** V, S
- **Duración:** Concentración, hasta 1 minuto
___
Intentas embelesar a un no muerto que puedas ver dentro del alcance. Debe superar una tirada de salvación de Sabiduría o quedará encantado por ti durante la duración. Si tú o tus aliados están combatiéndolo, tiene ventaja en la tirada de salvación.

Mientras esté encantado, tienes un vínculo telepático con él mientras ambos estén en el mismo plano de existencia. Puedes darle órdenes telepáticas (sin requerir acción), que hará lo mejor posible por obedecer. Puedes especificar una acción simple y general, como "Ataca a esa criatura", "Corre allí" o "Recoge ese objeto". Si la criatura cumple la orden y no recibe nuevas instrucciones, se defenderá y preservará lo mejor que pueda.

Puedes usar tu acción para tomar control total del objetivo. Hasta el final de tu próximo turno, solo hará las acciones que elijas y no hará nada que no permitas. Durante este tiempo, puedes hacer que use una reacción, pero debes usar tu propia reacción para ello.

Cada vez que el objetivo recibe daño, hace una nueva tirada de salvación de Sabiduría contra el hechizo. Si tiene éxito, el hechizo termina.

***A niveles superiores.*** Al lanzarlo con un espacio de nivel 5, la duración es concentración, hasta 10 minutos. Con un espacio de nivel 6, hasta 1 hora. Con un espacio de nivel 7 o superior, hasta 8 horas.

\columnbreak

#### Drenar Vida
*Nigromancia de nivel 1*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** 9 metros
- **Componentes:** V, S
- **Duración:** Concentración, hasta 1 minuto
___
Haces que un flujo de energía verde surja de los ojos y la boca de la criatura objetivo hacia tu mano, formando un lazo continuo de energía que los une.

Haz un ataque de conjuro a distancia contra la criatura. Si impactas, el objetivo recibe 1d8 de daño necrótico y, en cada uno de tus turnos siguientes mientras dure el hechizo, puedes usar tu acción adicional para infligir 1d8 de daño necrótico automáticamente. Cada vez que el objetivo sufre daño por este hechizo, recuperas puntos de golpe igual a la mitad del daño infligido, y su máximo de puntos de golpe se reduce en la misma cantidad hasta que complete un descanso prolongado.

Si fallas el ataque, puedes usar tu acción en turnos posteriores dentro de la duración del hechizo para intentar otro ataque de conjuro a distancia contra la misma criatura. El hechizo termina si usas tu acción para hacer otra cosa.

El hechizo también termina si el objetivo está a más de 9 metros de ti o tiene cobertura total al final de tu turno. Este hechizo no tiene efecto en constructos o no muertos.

***A niveles superiores.*** Cuando lanzas este hechizo con un espacio de nivel 2 o superior, el daño inicial aumenta en 1d8 por cada nivel de espacio por encima del 1. El daño infligido como acción adicional también aumenta en 1d8 por cada dos niveles de espacio adicionales por encima del 1.

#### Favor Temible
*Nigromancia de nivel 1*
___
- **Tiempo de lanzamiento:** 1 acción adicional
- **Alcance:** Uno mismo
- **Componentes:** V, S
- **Duración:** Concentración, hasta 1 minuto
___
Te ves fortalecido por el sufrimiento de tus víctimas. Hasta que el hechizo termine, tus ataques con armas infligen 1d4 de daño necrótico adicional al impactar.

<div class='footnote'>PARTE 2 | HECHIZOS</div>

\pagebreakNum

#### Espina Terrestre
*Transmutación de nivel 3*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** 18 metros
- **Componentes:** V, S, M (un guijarro de granito)
- **Duración:** Concentración, hasta 1 hora
___
Colocas tu mano sobre el suelo y evocas el elemento tierra, haciendo que una espina de tierra surja en un punto dentro del alcance. Una espina de 1,5 metros de radio y 4,5 metros de altura emerge del suelo. Cada criatura en esa área debe hacer una tirada de salvación de Destreza. Si falla, recibe 6d8 de daño contundente o la mitad de daño si tiene éxito. Las criaturas afectadas son empujadas lejos del punto del hechizo hacia el espacio vacío más cercano. Si fallan la salvación, también caen boca abajo.

La espina permanece mientras dure el hechizo o hasta que pierdas la concentración, momento en el que se derrumba, dejando el área como terreno difícil. Cuando colapsa, cada criatura a 1,5 metros debe hacer una tirada de salvación de Destreza o recibe 1d6 de daño contundente.

***A niveles superiores.*** Cuando lanzas este hechizo con un espacio de nivel 4 o superior, el daño aumenta en 1d8 por cada nivel de espacio por encima del 3.

#### Eclipse
*Transmutación de nivel 6*
___
- **Tiempo de lanzamiento:** 1 minuto
- **Alcance:** Uno mismo (radio de 8 kilómetros)
- **Componentes:** V, S, M (un vial de agua de un pozo lunar)
- **Duración:** Hasta 1 hora
___
Invocas a la diosa Elune para bloquear los rayos de An'she en un radio de 8 kilómetros alrededor de ti durante la duración. Debes estar en un área al aire libre para lanzar este hechizo.

Al lanzarlo, un eclipse bloquea gradualmente la luz natural en el transcurso de 1 minuto, sumergiendo cualquier área al aire libre en oscuridad total. El eclipse también afecta cualquier fuente de luz con un camino claro al cielo, transformando luz brillante en luz tenue y luz tenue en oscuridad. Cuando el hechizo termina, el eclipse desaparece gradualmente en el transcurso de 1 minuto mientras la luz natural regresa.

#### Choque Elemental
*Evocación de nivel 1*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** 18 metros
- **Componentes:** V, S, M (un trozo de azufre, granito, vidrio y una pluma)
- **Duración:** Instantánea
___
Manifiestas una ráfaga de energía elemental alrededor de una criatura dentro del alcance. Elige ácido, frío, fuego, rayo o trueno para el choque. La criatura debe hacer una tirada de salvación de Destreza, recibiendo 3d8 del tipo de daño elegido si falla o la mitad si tiene éxito.

***A niveles superiores.*** Cuando lanzas este hechizo con un espacio de nivel 2 o superior, el daño aumenta en 1d8 por cada nivel de espacio por encima del 1.

\columnbreak

#### Exorcismo
*Evocación de nivel 2*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** 9 metros
- **Componentes:** V, S, M (un frasco de agua bendita que se consume)
- **Duración:** Instantánea
___
Invocas fuerzas sagradas para dañar a criaturas impías. Realiza un ataque de conjuro a distancia contra una criatura dentro del alcance. Si impactas, recibe 3d8 de daño radiante. Además, si la criatura es una aberración, engendro o no muerto, recibe 2d8 de daño radiante adicional.

Si el objetivo está poseído o encantado por una aberración, engendro o no muerto, solo la criatura poseedora o encantadora recibe el daño si está dentro del alcance del hechizo, y el objetivo puede repetir su tirada de salvación contra la posesión o encantamiento con ventaja.

**A niveles superiores.** Al lanzarlo con un espacio de nivel 3 o superior, infliges 1d8 de daño radiante adicional por cada nivel de espacio por encima del 2.

#### Desvanecerse
*Ilusión de nivel 2*
___
- **Tiempo de lanzamiento:** 1 reacción, al recibir un golpe de un ataque
- **Alcance:** Uno mismo
- **Componentes:** V, S
- **Duración:** 1 asalto
___
Te desvanezcas de la vista de los demás, volviéndote invisible hasta el final de tu próximo turno. La invisibilidad termina antes si atacas, lanzas un hechizo o fuerzas a una criatura a hacer una tirada de salvación.

#### Llama Vil
*Truco de evocación*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** 18 metros
- **Componentes:** V, S
- **Duración:** Instantánea
___
Una llama verde se desliza por el suelo hacia una criatura dentro del alcance. Realiza un ataque de conjuro a distancia contra el objetivo. Si impactas, el objetivo recibe 1d8 de daño por fuego. La llama vil ignora la resistencia al fuego y las criaturas inmunes al daño por fuego se consideran resistentes.

El daño de este hechizo aumenta en 1d8 al alcanzar el nivel 5 (2d8), nivel 11 (3d8) y nivel 17 (4d8).

<div class='footnote'>PARTE 2 | HECHIZOS</div>

\pagebreakNum

#### Fuego y Azufre
*Evocación de nivel 4*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** 18 metros
- **Componentes:** V, S, M (un cráneo humanoide ennegrecido por el fuego)
- **Duración:** Instantánea
___
Una erupción de fuego condenatorio estalla desde un punto que elijas dentro del alcance, enviando seis llamaradas hacia objetivos en un radio de 9 metros. Puedes dirigir las llamas para golpear a un solo objetivo o a varios. Cada objetivo recibe 1d10 de daño por fuego por cada llama que lo golpee y puede hacer una tirada de salvación de Destreza para recibir la mitad de daño. Cada objetivo hace solo una tirada de salvación, independientemente de cuántas llamas lo golpeen.

***A niveles superiores.*** Cuando lanzas este hechizo con un espacio de nivel 5 o superior, crea una llama adicional por cada nivel de espacio por encima del 4.

#### Ráfaga
*Truco de evocación*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** 9 metros
- **Componentes:** V, S
- **Duración:** Instantánea
___
Tres fragmentos de hielo salen disparados hacia una o más criaturas dentro del alcance. Realiza un ataque de conjuro a distancia por cada fragmento. Puedes dirigirlos al mismo objetivo o a diferentes, pero todos golpean simultáneamente. Cada fragmento inflige 1d4 de daño por frío al impactar.

El daño de este hechizo aumenta en 1d4 por fragmento al alcanzar el nivel 5 (2d4), nivel 11 (3d4) y nivel 17 (4d4).

#### Toque Congelante
*Evocación de nivel 2*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** Toque
- **Componentes:** V, S, M (un fragmento de vidrio o hielo)
- **Duración:** 1 minuto
___
Tus dedos se vuelven fríos al tacto, cubiertos de escarcha. Realiza un ataque de conjuro cuerpo a cuerpo contra una criatura dentro del alcance. Si impactas, la criatura queda incapacitada e inmovilizada mientras dure el hechizo, ya que el hielo envuelve su cuerpo. El hechizo termina para una criatura afectada si sufre algún daño o si alguien usa una acción para romper el hielo.

\columnbreak

#### Rayo de Fuego y Escarcha
*Evocación de nivel 1*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** 36 metros
- **Componentes:** V, S, M (un trozo de vidrio y azufre)
- **Duración:** Instantánea
___
Lanzas un rayo de llamas azules hacia una criatura dentro del alcance. Realiza un ataque de conjuro a distancia contra la criatura. Si impactas, el objetivo recibe 2d6 de daño por fuego y 2d6 de daño por frío.

***A niveles superiores.*** Cuando lanzas este hechizo con un espacio de nivel 2 o superior, el daño por fuego y frío aumenta en 1d6 por cada nivel de espacio por encima del 1.

#### Pica Glacial
*Evocación de nivel 7*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** 36 metros
- **Componentes:** V, S
- **Duración:** Instantánea
___
Formas una gran pica de hielo sobre tu cabeza y la lanzas hacia una criatura que puedas ver dentro del alcance, haciendo que se rompa en su cuerpo. El objetivo debe hacer una tirada de salvación de Destreza. Si falla, recibe 8d8 + 40 de daño por frío; si tiene éxito, recibe la mitad de daño.

Si este daño reduce a una criatura a 0 puntos de golpe, se convierte en fragmentos de hielo, dejando todo lo que llevaba y vestía. Solo puede ser restaurada a la vida mediante una resurrección verdadera o un hechizo de deseo.

#### Guardián del Rey
*Abjuración de nivel 2*
___
- **Tiempo de lanzamiento:** 1 reacción, que tomas cuando una criatura recibe un ataque o un hechizo
- **Alcance:** 9 metros
- **Componentes:** V, S
- **Duración:** 1 asalto
___
Una barrera de luz sagrada protege a la criatura desencadenante. Hasta el inicio de tu próximo turno, la criatura gana resistencia a todo el daño causado por ataques de armas, hechizos y efectos similares, incluyendo el ataque desencadenante. El hechizo no protege contra fuentes de daño natural, como lava o caídas.

<div class='footnote'>PARTE 2 | HECHIZOS</div>

\pagebreakNum

#### Halo
*Evocación de nivel 7*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** Uno mismo (radio de 18 metros)
- **Componentes:** V, S
- **Duración:** Instantánea
___
Extiendes tus manos, creando una explosión de energía divina que se propaga desde ti. Puedes elegir crear un halo de Luz o Sombra.

**Luz.** Cada criatura dentro de 18 metros de ti es bañada por energía sagrada. Las criaturas hostiles deben hacer una tirada de salvación de Constitución o reciben 6d6 de daño radiante, y las criaturas aliadas recuperan 6d6 puntos de golpe. Si tienen éxito, reciben la mitad de daño.

**Sombra.** Las criaturas que elijas dentro de 18 metros de ti son golpeadas por energía sombría. Deben hacer una tirada de salvación de Constitución o reciben 6d6 de daño necrótico y 6d6 de daño psíquico. Si tienen éxito, reciben la mitad de daño.

Si hay 15 metros o más entre tú y una criatura al lanzar este hechizo, esa criatura hace la tirada de salvación con desventaja.

#### Lluvia Sanadora
*Transmutación de nivel 5*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** 36 metros
- **Componentes:** V, S, M (un vial de agua de lluvia)
- **Duración:** Concentración, hasta 1 minuto
___
Invocas una nube en un punto dentro del alcance, cubriendo un área de 4,5 metros de radio con lluvia. Cada criatura aliada que entre en la lluvia por primera vez en su turno, o que comience su turno dentro de la lluvia, recupera 2d6 puntos de golpe. La lluvia sanadora extingue fuegos no mágicos dentro de su área de efecto.

***A niveles superiores.*** Cuando lanzas este hechizo con un espacio de nivel 7 o superior, la sanación aumenta en 1d6 por cada dos niveles de espacio por encima del 5.

#### Nova Sagrada
*Evocación de nivel 3*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** Uno mismo (radio de 4,5 metros)
- **Componentes:** V, S
- **Duración:** Instantánea
___
Libera una ráfaga de energía sagrada en un radio de 4,5 metros a tu alrededor. Todas las criaturas aliadas recuperan 3d6 puntos de golpe, mientras que todas las criaturas hostiles deben hacer una tirada de salvación de Constitución, recibiendo 4d6 de daño radiante si fallan o la mitad si tienen éxito. Las aberraciones, engendros y no muertos hacen esta tirada con desventaja.

**A niveles superiores.** Cuando lanzas este hechizo con un espacio de nivel 4 o superior, la curación y el daño aumentan en 1d6 por cada nivel de espacio por encima del 3.

\columnbreak

#### Prisma Sagrado
*Evocación de nivel 2*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** 18 metros
- **Componentes:** S
- **Duración:** Instantánea
___
Una ráfaga de luz surge desde ti hacia una criatura dentro del alcance y se dispersa al impactar, tocando a tres criaturas adicionales de tu elección a 1,5 metros del objetivo. Cada criatura obtiene uno de los siguientes efectos de tu elección.

**Dañar.** La criatura debe hacer una tirada de salvación de Destreza, recibiendo 2d4 de daño radiante si falla o la mitad si tiene éxito.

**Sanar.** La criatura recupera un número de puntos de golpe igual a 1d4 + tu modificador de conjuro.

***A niveles superiores.*** Cuando lanzas este hechizo con un espacio de nivel 3 o superior, puedes aumentar el daño y la curación en 1d4 por cada nivel de espacio por encima del 2, o elegir una criatura adicional dentro de 1,5 metros del objetivo por cada nivel de espacio superior al 2.


#### Ira Sagrada
*Evocación de nivel 3*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** Uno mismo (radio de 4,5 metros)
- **Componentes:** V, S
- **Duración:** Instantánea
___
Libera una ráfaga de energía radiante. Cada criatura que elijas dentro de un radio de 6 metros alrededor de ti debe hacer una tirada de salvación de Sabiduría. Un objetivo recibe 6d6 de daño radiante si falla o la mitad si tiene éxito. La explosión se extiende por las esquinas.

***A niveles superiores.*** Cuando lanzas este hechizo con un espacio de nivel 4 o superior, el daño aumenta en 1d6 por cada nivel de espacio por encima del 3.

#### Explosión Aullante
*Evocación de nivel 2*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** 18 metros
- **Componentes:** V, S
- **Duración:** 1 asalto
___
Una ráfaga helada estalla alrededor de un punto de tu elección dentro del alcance. Cada criatura en una esfera de 4,5 metros de radio centrada en ese punto debe hacer una tirada de salvación de Constitución. Una criatura recibe 3d8 de daño por frío si falla o la mitad si tiene éxito. Una niebla helada permanece en el área, causando que esté fuertemente oscurecida. Dura hasta el final de la duración o hasta que un viento de velocidad moderada o mayor (al menos 16 km/h) la disperse.

***A niveles superiores.*** Cuando lanzas este hechizo con un espacio de nivel 3 o superior, el daño aumenta en 1d8 por cada nivel de espacio por encima del 2.

<div class='footnote'>PARTE 2 | HECHIZOS</div>

\pagebreakNum

#### Bloque de Hielo
*Abjuración de nivel 4*
___
- **Tiempo de lanzamiento:** 1 reacción, cuando recibes daño
- **Alcance:** Uno mismo
- **Componentes:** V, S
- **Duración:** Concentración, hasta 1 minuto
___
El hielo se materializa rápidamente a tu alrededor, protegiéndote del daño. Ganas 40 puntos de golpe temporales e inmunidad al daño por frío mientras dure el hechizo. Mientras el hechizo esté activo, no puedes moverte ni realizar acciones o reacciones. El hechizo permanece activo hasta que los puntos de golpe temporales se agoten o finalice su duración.

#### Nova de Hielo
*Evocación de nivel 8*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** 36 metros
- **Componentes:** V, S, M (polvo de vidrio y agua)
- **Duración:** Instantánea
___
El frío extremo se expande en un radio de 4,5 metros centrado en un punto que puedas ver dentro del alcance. Cada criatura en el área debe hacer una tirada de salvación de Destreza. Si falla, recibe 10d6 de daño por frío y queda inmovilizada durante 1 minuto al ser encerrada por hielo. Si tiene éxito, recibe la mitad de daño y no queda inmovilizada.

Una criatura inmovilizada por el hielo puede usar su acción para hacer una prueba de Fuerza contra la CD de tu hechizo. Si tiene éxito, se libera. Alternativamente, el hielo puede ser destruido si recibe un total de 40 puntos de daño. Tiene una clase de armadura de 10.

#### Fortaleza de Hielo
*Transmutación de nivel 2*
___
- **Tiempo de lanzamiento:** 1 reacción, que tomas cuando recibes daño contundente, perforante o cortante
- **Alcance:** Uno mismo
- **Componentes:** V, S
- **Duración:** 1 asalto
___
Congelas temporalmente tu propia sangre y haces que tu piel se vuelva tan dura como el hielo. Hasta el inicio de tu próximo turno, tienes resistencia al daño contundente, perforante y cortante, incluido el daño desencadenante.

#### Toque Helado
*Nigromancia de nivel 1*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** 18 metros
- **Componentes:** V, S
- **Duración:** 1 asalto
___
Invocas energía helada para atacar a una criatura que puedas ver dentro del alcance, congelándola con el frío de la tumba. Realiza un ataque de conjuro a distancia contra la criatura. Si impactas, el objetivo recibe 3d8 de daño por frío y no puede recuperar puntos de golpe hasta el inicio de tu próximo turno. Hasta entonces, la piel del objetivo se torna pálida como el hielo. Si impactas a un objetivo celestial, tiene desventaja en sus tiradas de ataque contra ti hasta el final de tu próximo turno.

***A niveles superiores.*** Cuando lanzas este hechizo con un espacio de nivel 2 o superior, el daño aumenta en 1d8 por cada nivel de espacio por encima del 1.

#### Fuego Interno
*Abjuración de nivel 1*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** Uno mismo
- **Componentes:** V, S
- **Duración:** 8 horas
___
Te proteges mediante tu fe y convicciones. Mientras no lleves armadura, tu CA base se convierte en 11 + tu modificador de conjuro, y tienes ventaja en las tiradas de salvación para evitar o terminar la condición de asustado sobre ti. El hechizo termina si te pones una armadura.

#### Enfoque Interno
*Abjuración de nivel 2*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** Toque
- **Componentes:** V, S
- **Duración:** 1 hora
___
Tocas a una criatura dispuesta y amplificas su concentración a través de sus convicciones. La siguiente prueba de habilidad que realice mientras esté bajo el efecto de este hechizo se ve mejorada, sumando tu modificador de conjuro, tras lo cual el hechizo termina.

#### Voluntad Interna
*Abjuración de nivel 2*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** Toque
- **Componentes:** V, S
- **Duración:** 1 hora
___
Tocas a una criatura dispuesta y refuerzas su voluntad mediante sus convicciones. El objetivo suma tu modificador de conjuro al suyo al hacer tiradas de salvación de Sabiduría. Este efecto dura hasta que el hechizo termine o hasta que el objetivo supere una tirada de salvación de Sabiduría que de otro modo habría fallado.

#### Invocar Elementos
*Truco de transmutación*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** 9 metros
- **Componentes:** V, S
- **Duración:** Hasta 1 minuto
___
Invocas una pequeña porción de los elementos. Creas uno de los siguientes efectos mágicos dentro del alcance:

- Creas un efecto sensorial inofensivo que predice el clima durante las próximas 24 horas. Este efecto persiste por 1 asalto.
- Prendes o apagas una pequeña llama.
- Haces que las llamas parpadeen, se intensifiquen, disminuyan o cambien de color durante 1 minuto.
- Provocas temblores inofensivos en el suelo durante 1 minuto.
- Enfrías o calientas una pequeña cantidad de líquido.

Puedes tener hasta tres efectos de 1 minuto de duración activos al lanzar este hechizo varias veces, y puedes disipar un efecto como acción.

<div class='footnote'>PARTE 2 | HECHIZOS</div>

\pagebreakNum

#### Nave Voladora de Jaina
*Transmutación de nivel 9*
___
- **Tiempo de lanzamiento:** 1 minuto
- **Alcance:** Toque
- **Componentes:** V, S
- **Duración:** 24 horas
___
Canalizas tu poder en una nave no mágica dentro del alcance, que no debe exceder los 30 metros de largo y 9 metros de ancho. Durante la duración del hechizo, la nave adquiere una velocidad de vuelo de 18 metros y cambia de dirección y altitud según tus comandos, manteniendo su curso hasta recibir nuevas instrucciones o hasta que finalice la duración del hechizo.

La nave voladora tiene una clase de armadura de 15, 300 puntos de golpe, inmunidad al daño por veneno y psíquico, y es inmune a todas las condiciones.

Posee una capacidad de carga máxima de 50 toneladas (limitada por el tamaño de la nave). No se ralentiza hasta alcanzar su capacidad máxima, momento en el cual pierde la capacidad de volar y cae a una velocidad de 18 metros por asalto hasta tocar el suelo. No sufre daño por caída y sus pasajeros no resultan dañados.

Puedes hacer este efecto permanente lanzando este hechizo en la misma nave una vez por semana durante un año.

#### Estallido de Lava
*Evocación de nivel 2*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** 18 metros
- **Componentes:** V, S
- **Duración:** Instantánea
___
Manifiestas piedra fundida y magma en una bola feroz que lanzas hacia un objetivo dentro del alcance. El objetivo debe hacer una tirada de salvación de Destreza. Si falla, recibe 3d6 de daño por fuego y 3d6 de daño contundente; si tiene éxito, recibe la mitad de daño.

***A niveles superiores.*** Cuando lanzas este hechizo con un espacio de nivel 3 o superior, el daño aumenta en 1d6 de daño por fuego y 1d6 de daño contundente por cada nivel de espacio por encima del 2.

#### Luz del Protector
*Evocación de nivel 5*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** Uno mismo
- **Componentes:** V, S
- **Duración:** Instantánea
___
Sientes el calor de la luz dentro de ti mientras una oleada de energía positiva te recorre, restaurando un número de puntos de golpe igual a 5d12 + 30. Este hechizo también elimina la ceguera, sordera y cualquier enfermedad que te afecte.

\columnbreak

#### Ráfaga de Relámpago
*Truco de evocación*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** 18 metros
- **Componentes:** S
- **Duración:** Instantánea
___
Un arco de relámpago sale disparado de tus manos hacia una criatura dentro del alcance. Realiza un ataque de conjuro a distancia. Si impactas, el objetivo recibe 1d8 de daño por rayo. Si el objetivo lleva armadura de metal, en su lugar recibe 1d12 de daño por rayo.

El daño de este hechizo aumenta en 1d8 al alcanzar el nivel 5 (2d8 o 2d12), nivel 11 (3d8 o 3d12) y nivel 17 (4d8 o 4d12).

#### Escudo de Relámpagos
*Abjuración de nivel 1*
___
- **Tiempo de lanzamiento:** 1 acción adicional
- **Alcance:** 18 metros
- **Componentes:** S
- **Duración:** Concentración, hasta 10 minutos
___
Llamas al elemento aire y rodeas a un aliado dentro del alcance con un campo de electricidad crepitante. Hasta que el hechizo termine, el objetivo obtiene un bono de +1 a la CA y, cuando una criatura lo golpea con un ataque cuerpo a cuerpo, esa criatura recibe 1d4 de daño por rayo.

***A niveles superiores.*** Cuando lanzas este hechizo con un espacio de nivel 2 o superior, el daño aumenta en 1d4 por cada nivel de espacio por encima del 1.

#### Bomba Viva
*Evocación de nivel 2*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** 18 metros
- **Componentes:** V, S, M (un líquido inflamable)
- **Duración:** Concentración, hasta 1 minuto
___
Manipulas el maná que fluye a través de una criatura dentro del alcance, haciendo que arda por dentro con un fuego rugiente. El objetivo debe hacer una tirada de salvación de Constitución, recibiendo 1d10 de daño por fuego si falla. Si tiene éxito, recibe la mitad de daño y el hechizo termina. Al inicio de cada uno de tus turnos mientras persista el hechizo, el objetivo debe repetir la tirada de salvación con los mismos efectos en caso de éxito o fallo.

Cuando el hechizo termine, el objetivo y cada criatura a 3 metros de él deben hacer una tirada de salvación de Destreza, recibiendo 2d6 de daño por fuego si fallan o la mitad si tienen éxito.

***A niveles superiores.*** Cuando lanzas este hechizo con un espacio de nivel 3 o superior, el daño de la explosión aumenta en 1d6 por cada nivel de espacio por encima del 2.

<div class='footnote'>PARTE 2 | HECHIZOS</div>

\pagebreakNum

#### Barrera Luminosa
*Abjuración de nivel 4*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** Uno mismo (radio de 4,5 metros)
- **Componentes:** V, S
- **Duración:** Concentración, hasta 1 minuto
___
Manifiestas un domo de luz brillante a tu alrededor para proteger a tus aliados y dificultar a tus enemigos. Hasta que el hechizo termine, el domo se mueve contigo, centrado en ti. Todas las criaturas aliadas dentro del domo ganan un bono de +2 a la CA frente a ataques de hechizos, las tiradas de ataque de hechizos contra ellos que provengan de fuera del domo se hacen con desventaja, y si una criatura recibe daño de un ataque con arma, el daño se reduce en 3 puntos.

**A niveles superiores.** Cuando lanzas este hechizo con un espacio de nivel 5 o superior, la reducción de daño aumenta en 1 por cada nivel de espacio por encima del 4.

#### Golpe Lunar
*Truco de evocación*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** 18 metros
- **Componentes:** V, S
- **Duración:** Instantánea
___
Una ráfaga de energía lunar atraviesa el aire. Elige una criatura dentro del alcance, o elige dos criaturas dentro del alcance que estén a 1,5 metros una de otra. Un objetivo debe hacer una tirada de salvación de Destreza o recibe 1d6 de daño de fuerza.

Si lanzas este hechizo al aire libre con una vista clara de la luna, el hechizo inflige 1d8 de daño de fuerza.

***A niveles superiores.*** El daño del hechizo aumenta en un dado al alcanzar el nivel 5 (2d6 o 2d8), nivel 11 (3d6 o 3d8) y nivel 17 (4d6 o 4d8).

#### Manto del Cruzado Caído
*Evocación de nivel 3*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** Uno mismo (radio de 9 metros)
- **Componentes:** V
- **Duración:** Concentración, hasta 1 minuto
___
Un poder profano emana de ti en un aura de 9 metros de radio, despertando sed de sangre en las criaturas aliadas. Hasta que el hechizo termine, el aura se mueve contigo, centrada en ti. Mientras estén en el aura, cada criatura no hostil (incluyéndote a ti) inflige 1d4 de daño necrótico adicional cuando impacta con un ataque con arma.

\columnbreak

#### Disipar en Masa
*Abjuración de nivel 6*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** 27 metros
- **Componentes:** V, S
- **Duración:** Instantánea
___
Elige una esfera de 4,5 metros de radio dentro del alcance. Cualquier hechizo de nivel 3 o inferior en el objetivo termina. Por cada hechizo de nivel 4 o superior en el objetivo, haz una prueba de habilidad usando tu habilidad de conjuro. La CD es igual a 10 + el nivel del hechizo. Si la prueba tiene éxito, el hechizo termina.

***A niveles superiores.*** Cuando lanzas este hechizo con un espacio de nivel 7 o superior, terminas automáticamente los efectos de un hechizo en el objetivo si el nivel del hechizo es igual o menor al nivel del espacio de conjuro que usaste menos 3.

#### Explosión Mental
*Truco de evocación*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** 18 metros
- **Componentes:** V, S
- **Duración:** Instantánea
___
Intentas penetrar las defensas mentales de una criatura que puedas ver dentro del alcance. El objetivo debe superar una tirada de salvación de Sabiduría o recibir 1d8 de daño psíquico. Si este daño obliga a hacer una prueba de concentración, dicha prueba se hace con desventaja.

El daño de este hechizo aumenta en 1d8 al alcanzar el nivel 5 (2d8), nivel 11 (3d8) y nivel 17 (4d8).

#### Desgarrar Mente
*Encantamiento de nivel 2*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** 36 metros
- **Componentes:** V
- **Duración:** Concentración, hasta 1 minuto
___
Envuelves la mente de una criatura que puedas ver dentro del alcance. El objetivo debe hacer una tirada de salvación de Sabiduría. Si falla, recibe 2d6 de daño psíquico o la mitad si tiene éxito.

Además del daño, una criatura que falle la tirada de salvación tiene desventaja en todas las tiradas de ataque y pruebas de habilidad mientras dure el hechizo. Al final de cada uno de sus turnos, puede repetir la tirada de salvación de Sabiduría, terminando el efecto si tiene éxito.

***A niveles superiores.*** Cuando lanzas este hechizo con un espacio de nivel 3 o superior, el daño aumenta en 1d6 por cada nivel de espacio por encima del 2.

<div class='footnote'>PARTE 2 | HECHIZOS</div>

\pagebreakNum

#### Visión Mental
*Adivinación de nivel 1*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** Toque
- **Componentes:** V, S
- **Duración:** Concentración, hasta 1 hora
___
Extiendes tu mano y tocas a una criatura dispuesta. Durante la duración del hechizo, ves a través de los ojos de la criatura y escuchas lo que escucha. Durante este tiempo, pierdes tus propios sentidos y eres considerado ciego, sordo y aturdido. Puedes terminar tu visión mental como una acción libre en tu turno.

#### Horror Psíquico
*Ilusión de nivel 3*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** Uno mismo
- **Componentes:** V, S
- **Duración:** Concentración, hasta 1 minuto
___
Proyectas una corriente fantasmal de miedo a tu alrededor, creando una explosión de energía mental. Cada criatura en una esfera de 4,5 metros centrada en ti debe superar una tirada de salvación de Sabiduría o soltar lo que esté sosteniendo y quedar asustada durante la duración. Mientras esté asustada, la criatura solo puede usar la acción de Correr para alejarse de ti por la ruta más segura disponible, a menos que no tenga dónde moverse. Si termina su turno en un lugar donde no tenga línea de visión contigo, puede hacer otra tirada de salvación de Sabiduría. Si tiene éxito, el hechizo termina para esa criatura.

Si la criatura ya estaba asustada y falla la tirada, también queda aturdida mientras permanezca asustada o hasta que reciba daño.

#### Piroexplosión
*Evocación de nivel 7*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** 36 metros
- **Componentes:** V, S, M (un trozo de azufre)
- **Duración:** Instantánea
___
Juntas tus manos, conjurando una bola de magma goteante que lanzas hacia una criatura u objeto dentro del alcance. Realiza un ataque de conjuro a distancia contra el objetivo. Si impactas, el objetivo recibe 13d10 de daño por fuego y se prende en llamas. Hasta que una criatura use una acción para apagar el fuego, el objetivo recibe 1d10 de daño por fuego al inicio de cada uno de sus turnos.

***A niveles superiores.*** Cuando lanzas este hechizo con un espacio de nivel 8 o superior, el daño inicial aumenta en 1d10 por cada nivel de espacio por encima del 7.

\columnbreak

#### Lluvia de Fuego
*Evocación de nivel 5*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** 36 metros
- **Componentes:** V, S, M (un trozo de azufre y un trozo de hierro)
- **Duración:** Concentración, hasta 1 minuto
___
Una lluvia de pequeños meteoritos cae del cielo, explotando al impactar. Causas que caigan en un cilindro de 9 metros de altura y 4,5 metros de radio centrado en un punto dentro del alcance. Cada criatura que entre en el área por primera vez en su turno o que comience su turno allí debe hacer una tirada de salvación de Destreza, recibiendo 3d6 de daño contundente y 3d6 de daño por fuego si falla, o la mitad si tiene éxito.

Como acción adicional, puedes mover el cilindro hasta 4,5 metros hacia un punto que puedas ver. Los objetos inflamables no atendidos en el área se incendian, y los metales comienzan a fundirse.

***A niveles superiores.*** Cuando lanzas este hechizo con un espacio de nivel 6 o superior, el daño por fuego aumenta en 2d6 por cada nivel de espacio por encima del 5.

#### Reencarnación
*Nigromancia de nivel 5*
___
- **Tiempo de lanzamiento:** 10 minutos
- **Alcance:** Uno mismo
- **Componentes:** V, S, M (un ankh enjoyado con un valor de 500 po)
- **Duración:** 10 días
___
Proteges tu alma con el poder de los elementos. Si mueres durante la duración del hechizo, eres devuelto a la vida instantáneamente con la mitad de tus puntos de golpe y el componente material se consume.

Este hechizo neutraliza cualquier veneno y cura enfermedades normales que te afecten cuando mueras. Sin embargo, no elimina enfermedades mágicas, maldiciones y efectos similares; si dichos efectos no se eliminan antes de morir, continúan afectándote.

Este hechizo cierra todas las heridas mortales y restaura cualquier parte del cuerpo que falte.

Regresar de la muerte es un proceso agotador. Sufres una penalización de -4 a todas las tiradas de ataque, tiradas de salvación y pruebas de habilidad. Cada vez que completes un descanso prolongado, la penalización se reduce en 1 hasta que desaparezca.

Si lanzas este hechizo de nuevo, el efecto de cualquier hechizo de reencarnación lanzado previamente termina. El hechizo finaliza prematuramente si el componente material no está contigo.

#### Arrepentimiento
*Encantamiento de nivel 1*
___
- **Tiempo de lanzamiento:** 1 reacción, que tomas cuando eres objetivo de un ataque con arma o hechizo
- **Alcance:** 9 metros
- **Componentes:** V
- **Duración:** 1 asalto
___
Un sentido de remordimiento invade a la criatura desencadenante. La criatura debe hacer una tirada de salvación de Sabiduría. Si falla, debe elegir un nuevo objetivo o perder el ataque o hechizo.

<div class='footnote'>PARTE 2 | HECHIZOS</div>

\pagebreakNum

#### Golpe Justiciero
*Evocación de nivel 2*
___
- **Tiempo de lanzamiento:** 1 acción adicional
- **Alcance:** Uno mismo
- **Componentes:** V
- **Duración:** Concentración, hasta 1 minuto
___
La próxima vez que golpees con un ataque cuerpo a cuerpo durante la duración del hechizo, tu ataque inflige 2d6 de daño radiante adicional, y la siguiente tirada de ataque contra este objetivo antes del final de tu próximo turno se realiza con ventaja.

***A niveles superiores.*** Cuando lanzas este hechizo con un espacio de nivel 3 o superior, el daño adicional aumenta en 1d6 por cada nivel de espacio por encima del 2.

#### Ritual de Invocación
*Conjuración de nivel 5 (ritual)*
___
- **Tiempo de lanzamiento:** 10 minutos
- **Alcance:** 3 metros
- **Componentes:** V, S, M (un zafiro de sangre con un valor de 100 po)
- **Duración:** 1 hora
___
Llamas a un portal de invocación en un espacio vacío dentro del alcance. Aparece como una estatua sombría de una figura encapuchada, sosteniendo su manto abierto para revelar un torbellino hacia el Vacío Abisal.

Usando 1 minuto, puedes canalizar energía en la estatua y llamar el verdadero nombre de una criatura. Si la criatura está en tu plano de existencia, aparece un espejo brillante frente a ella que solo ella puede ver, a través del cual puede percibirte a ti y tu entorno, pero tú no puedes verla.

La criatura puede ignorar el espejo, haciendo que desaparezca después de 1 minuto, y no podrá volver a aparecer para esa criatura durante 24 horas, o puede atravesarlo, siendo teletransportada al espacio frente a la piedra de invocación.

El ritual solo puede llamar criaturas hacia él, y no pueden usar la piedra para regresar a su ubicación previa.

\columnbreak

#### Salvación
*Abjuración de nivel 9*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** Uno mismo (radio de 18 metros)
- **Componentes:** V, S, M (una lágrima de desesperación)
- **Duración:** 1 asalto
___
Emites una radiancia sagrada en un radio de 18 metros. Cada criatura de tu elección dentro del alcance es inmune a todo daño hasta que el hechizo termine. Las criaturas afectadas por este hechizo también son curadas de cualquier efecto que las incapacite, paralice, aturda o petrifique.

#### Cisma
*Encantamiento de nivel 6*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** 9 metros
- **Componentes:** V, S
- **Duración:** 1 asalto
___
Atacas el alma de una criatura con energía oscura. Elige una criatura dentro del alcance. El objetivo debe hacer una tirada de salvación de Carisma, recibiendo 8d6 de daño psíquico si falla o la mitad si tiene éxito. Si falla, la criatura queda maldita durante la duración. La próxima vez que tú o un aliado golpeen a la criatura maldita con un ataque, la criatura tiene vulnerabilidad a todo el daño de ese ataque, y la maldición termina.

#### Encadenar No Muertos
*Encantamiento de nivel 2*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** 18 metros
- **Componentes:** V, S, M (un pequeño trozo de cadena)
- **Duración:** 1 minuto
___
Elige una criatura no muerta que puedas ver dentro del alcance. El objetivo debe hacer una tirada de salvación de Sabiduría. Si falla, queda aturdido durante la duración o hasta que reciba daño. Al final de cada uno de sus turnos, el objetivo puede realizar una nueva tirada de salvación de Sabiduría. Si tiene éxito, el hechizo termina.

***A niveles superiores.*** Cuando lanzas este hechizo con un espacio de nivel 3 o superior, puedes elegir una criatura adicional por cada nivel de espacio por encima del 2. Las criaturas deben estar a 9 metros unas de otras cuando las elijas.

<div class='footnote'>PARTE 2 | HECHIZOS</div>

\pagebreakNum

#### Rayo de Sombra
*Truco de nigromancia*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** 36 metros
- **Componentes:** V, S
- **Duración:** Instantánea
___
Lanzas una ráfaga de energía necrótica hacia una criatura dentro del alcance. Realiza un ataque de conjuro a distancia contra el objetivo. Si impactas, el objetivo recibe 1d8 de daño necrótico.

Cuando el hechizo impacta, puedes elegir recibir 1 punto de daño psíquico para aumentar el daño infligido a 1d12 de daño necrótico.

El daño del hechizo aumenta en un dado adicional al alcanzar el nivel 5 (2d8 o 2d12), nivel 11 (3d8 o 3d12) y nivel 17 (4d8 o 4d12). El daño opcional recibido aumenta en 2 puntos al alcanzar el nivel 5 (3), nivel 11 (5) y nivel 17 (7).

#### Choque Sombrío
*Nigromancia de nivel 5*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** 36 metros
- **Componentes:** V, S
- **Duración:** Instantánea
___
Energía sombría gotea de tu mano mientras la llevas al suelo, envolviendo un punto que puedas ver dentro del alcance en oscuridad. Cada criatura en una esfera de 6 metros de radio centrada en ese punto debe hacer una tirada de salvación de Constitución. Una criatura recibe 4d8 de daño necrótico y 4d8 de daño psíquico si falla, o la mitad de daño si tiene éxito. La oscuridad se extiende por las esquinas y el área del hechizo queda oscurecida por oscuridad mágica hasta el final de tu próximo turno.

***A niveles superiores.*** Cuando lanzas este hechizo con un espacio de nivel 6 o superior, el daño aumenta en 1d8 por cada nivel de espacio por encima del 5.

#### Deslizar Sombrío
*Truco de conjuración*
___
- **Tiempo de lanzamiento:** 1 acción adicional
- **Alcance:** Uno mismo (1,5 metros)
- **Componentes:** V
- **Duración:** Instantánea
___
Te envuelves en sombras y te teletransportas a un espacio desocupado dentro de 1,5 metros.

\columnbreak

#### Furia Sombría
*Encantamiento de nivel 6*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** 18 metros
- **Componentes:** V, S
- **Duración:** Concentración, hasta 1 minuto
___
Extiendes tu brazo y atraes energía sombría hacia criaturas dentro de un radio de 3 metros de un punto dentro del alcance. Cada criatura recibe 5d8 de daño psíquico y debe hacer una tirada de salvación de Sabiduría. Si falla, queda aturdida durante la duración del hechizo.

Una criatura aturdida debe hacer una tirada de salvación de Constitución al final de cada uno de sus turnos. Si tiene éxito, el efecto de aturdimiento termina.

#### Apariciones Sombrías
*Conjuración de nivel 4*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** 18 metros
- **Componentes:** V, S
- **Duración:** Concentración, hasta 1 minuto
___
Manipulas las sombras a tu alrededor, enviando apariciones para acosar a tu enemigo. Creas tres apariciones sombrías de tamaño mediano en espacios desocupados a 3 metros de ti. Elige un objetivo dentro del alcance para cada aparición. Cada aparición puede tener el mismo o diferente objetivo. Al final de cada uno de tus turnos, tus apariciones se mueven 6 metros hacia su objetivo, atravesando criaturas y obstáculos, e ignorando terreno difícil.

Cuando una aparición está en el mismo espacio que otra criatura, explota, obligando a esa criatura a hacer una tirada de salvación de Inteligencia. Si falla, recibe 8d6 de daño psíquico o la mitad si tiene éxito. Una criatura que falle esta tirada de salvación también ve su velocidad de movimiento reducida a 0 hasta el inicio de su próximo turno.

Después de perder la concentración en este hechizo, todas las apariciones presentes duran 1 asalto.

**A niveles superiores.** Cuando lanzas este hechizo con un espacio de nivel 5 o superior, las apariciones infligen 1d6 de daño psíquico adicional por cada nivel de espacio por encima del 4.

#### Fuerza Radiante
*Abjuración de nivel 2*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** 9 metros
- **Componentes:** V, S
- **Duración:** Concentración, hasta 1 minuto
___
Una luz brillante emana de una criatura que puedes ver dentro del alcance, empujando a las criaturas hostiles. Cada criatura que elijas en un radio de 3 metros del objetivo debe hacer una tirada de salvación de Destreza. Si falla, es empujada 3 metros del objetivo y derribada. Durante la duración del hechizo, puedes usar tu acción para hacer que la fuerza radiante estalle desde la criatura elegida nuevamente.

<div class='footnote'>PARTE 2 | HECHIZOS</div>

\pagebreakNum

#### Ira Solar
*Truco de evocación*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** 18 metros
- **Componentes:** V, S
- **Duración:** Instantánea
___
Liberas una ráfaga de la ira del sol contra una criatura dentro del alcance. Realiza un ataque de conjuro a distancia contra la criatura. Si impactas, el objetivo recibe 1d8 de daño radiante y, hasta el final de tu próximo turno, emite luz brillante en un radio de 3 metros y luz tenue en un radio adicional de 3 metros.

El daño de este hechizo aumenta en 1d8 al alcanzar el nivel 5 (2d8), nivel 11 (3d8) y nivel 17 (4d8).

#### Robar Hechizo
*Abjuración de nivel 3*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** 18 metros
- **Componentes:** V, S
- **Duración:** Instantánea
___
Elige una criatura que puedas ver dentro del alcance. Un efecto de hechizo de nivel 1 de tu elección que afecte al objetivo se transfiere a ti. Durante su duración restante, el efecto del hechizo se aplica a ti como si lo hubieras lanzado tú mismo.

Si el hechizo robado requiere concentración, debes concentrarte en él. No necesitas proporcionar componentes adicionales de lanzamiento, si es que el hechizo robado los requería. Robar Hechizo no tiene efecto sobre hechizos que crean o convocan criaturas, ni sobre efectos de hechizos que no pueden ser eliminados por *disipar magia*.

No puedes cambiar el hechizo robado de cómo fue lanzado originalmente, a menos que su descripción permita explícitamente cambios después de ser lanzado.

Para robar un efecto de hechizo de nivel 2 o superior, haz una prueba de habilidad usando tu habilidad de conjuro. La CD es igual a 10 + el nivel del hechizo. Si tienes éxito, robas el hechizo.

***A niveles superiores.*** Cuando lanzas este hechizo con un espacio de nivel 4 o superior, el nivel de hechizo donde tienes éxito automáticamente en la prueba aumenta en uno por cada nivel de espacio por encima del 3.

#### Lluvia de Estrellas
*Evocación de nivel 6*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** 90 metros
- **Componentes:** V, S, M (una pizca de vidrio pulverizado)
- **Duración:** 1 asalto
___
Incontables destellos de luz pura de luna caen al suelo en un cilindro de 12 metros de altura y 6 metros de radio centrado en un punto dentro del alcance. Cada criatura en el cilindro debe hacer una tirada de salvación de Destreza. Una criatura recibe 10d6 de daño radiante si falla o la mitad si tiene éxito. Una criatura que falle también queda cegada hasta el final de tu próximo turno.

Si lanzas este hechizo al aire libre con una vista clara de la luna, inflige 2d6 de daño radiante adicional.

***A niveles superiores.*** Cuando lanzas este hechizo con un espacio de nivel 7 o superior, el daño aumenta en 1d6 por cada nivel de espacio por encima del 6.

\columnbreak

#### Fuego Estelar
*Evocación de nivel 1*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** 36 metros
- **Componentes:** V, S
- **Duración:** Instantánea
___
Un destello de luz cae sobre una criatura de tu elección dentro del alcance. Realiza un ataque de conjuro a distancia contra el objetivo. Si impactas, el objetivo recibe 3d6 de daño radiante y queda cegado hasta el final de tu próximo turno. La ceguera termina antes si el objetivo recibe daño de un ataque con arma o hechizo, ya que el polvo estelar que bloquea sus ojos es removido.

Si lanzas este hechizo al aire libre con una vista clara de la luna, inflige 1d6 de daño radiante adicional.

***A niveles superiores.*** Cuando lanzas este hechizo con un espacio de nivel 2 o superior, el daño aumenta en 1d6 por cada nivel de espacio por encima del 1.

#### Oleada de Estrellas
*Evocación de nivel 3*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** Uno mismo (línea de 30 metros)
- **Componentes:** V, S, M (una varilla de vidrio y un vial de agua de un pozo lunar)
- **Duración:** Instantánea
___
Una ráfaga de intensa luz lunar se proyecta en una línea de 30 metros de largo y 1,5 metros de ancho desde ti en una dirección que elijas. Cada criatura en el camino de la ráfaga debe hacer una tirada de salvación de Destreza; las criaturas sensibles a la luz solar tienen desventaja en esta tirada. Una criatura recibe 6d6 de daño radiante si falla o la mitad si tiene éxito.

Si lanzas este hechizo al aire libre con una vista clara de la luna, inflige 2d6 de daño radiante adicional.

***A niveles superiores.*** Cuando lanzas este hechizo con un espacio de nivel 4 o superior, el daño aumenta en 1d6 por cada nivel de espacio por encima del 3.

#### Convocar Ser del Vacío
*Conjuración de nivel 4*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** 27 metros
- **Componentes:** V, S, M (un ojo en un vial valorado al menos en 400 po)
- **Duración:** Concentración, hasta 1 hora
___
Llamas a una criatura del Vacío que se manifiesta físicamente en un espacio desocupado que puedas ver dentro del alcance. Esta forma corpórea utiliza la estadística de Espíritu del Vacío. Cuando lanzas el hechizo, elige entre Manipulador Mental, Psicoengendro o Sombraengendro. La criatura se parece a la opción elegida y determina ciertos rasgos en su estadística. La criatura desaparece cuando sus puntos de golpe llegan a 0 o cuando el hechizo termina.

La criatura es un aliado para ti y tus compañeros. En combate, comparte tu cuenta de iniciativa, pero toma su turno inmediatamente después del tuyo. Obedece tus comandos verbales (no se requiere acción de tu parte). Si no das ninguna orden, toma la acción Esquivar y usa su movimiento para evitar el peligro.

**A niveles superiores.** Cuando lanzas este hechizo con un espacio de nivel 5 o superior, usa el nivel superior donde aparezca el nivel del hechizo en la estadística.

<div class='footnote'>PARTE 2 | HECHIZOS</div>

\pagebreakNum

___
> ## Ser del Vacío
>*Aberración Mediana*
> ___
> - **Clase de Armadura** 11 + el nivel del conjuro
> - **Puntos de Golpe** 40 + 10 por cada nivel de conjuro por encima del 3
> - **Velocidad** 9 metros, volar 12 metros (solo Manipulador Mental; puede flotar)
>___
>|FUE|DES|CON|INT|SAB|CAR|
>|:---:|:---:|:---:|:---:|:---:|:---:|
>|14(+2)|11(+0)|13(+1)|4(-3)|14(+2)|16(+3)|
>___
> - **Resistencias al Daño** necrótico, psíquico
> - **Inmunidades a Condiciones** hechizado, asustado  
> - **Sentidos** visión en la oscuridad 36 metros, Percepción pasiva
> - **Idiomas** entiende el idioma que hablas
> - **Bonificación de Competencia:** Tu bonificación de competencia
>
> - **Desafío** -
> ___
> ### Acciones
> ***Multiataque.*** La aberración hace un número de ataques igual a la mitad del nivel del conjuro.
>
> ***Mordisco (Solo Sombraengendro).*** *Ataque de arma cuerpo a cuerpo:* tu modificador de ataque de conjuro para golpear, alcance 1,5 metros, una criatura. *Impacto:* 1d8 + 3 + el nivel del conjuro de daño perforante, y si el objetivo es una criatura, debe superar una tirada de salvación de Constitución contra tu CD de conjuro o quedar envenenado hasta el inicio del siguiente turno de la aberración.
>
> ***Tentáculo (Solo Manipulador Mental).*** *Ataque de arma cuerpo a cuerpo:* tu modificador de ataque de conjuro para golpear, alcance 1,5 metros, una criatura. *Impacto:* 1d8 + 3 + el nivel del conjuro de daño contundente. Si el objetivo es una criatura Grande o más pequeña, queda apresado (CD 16 para escapar); sin embargo, la velocidad del objetivo no se reduce a 0. Hasta que el apresamiento termine, la aberración comparte el espacio con el objetivo, el objetivo queda cegado y la aberración no puede usar sus tentáculos en otro objetivo sin finalizar el apresamiento.
>
> ***Desgarrar Psíquico (Solo Psicoengendro).*** *Ataque de conjuro a distancia:* tu modificador de ataque de conjuro para golpear, alcance 9 metros, una criatura. *Impacto:* 1d8 + 3 + el nivel del conjuro de daño psíquico. Si el objetivo es una criatura, no puede recuperar puntos de golpe hasta el inicio del próximo turno de la aberración.

\columnbreak

#### Toque del Caos
*Truco de evocación*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** 36 metros
- **Componentes:** V, S
- **Duración:** Instantánea
___
Lanzas un rayo de energía de caos puro hacia una criatura u objeto dentro del alcance. Realiza un ataque de conjuro a distancia contra el objetivo. Si impactas, tira un d8 para determinar el tipo de daño que inflige de acuerdo a la tabla siguiente. Luego tira 1d8 para el daño.

d8 | Tipo de Daño | d8 | Tipo de Daño
---|--------------|---|--------------
1  | Ácido         | 5  | Relámpago
2  | Frío          | 6  | Veneno
3  | Fuego         | 7  | Psíquico
4  | Fuerza        | 8  | Trueno

El hechizo crea más de un rayo al alcanzar niveles superiores: dos rayos al nivel 5, tres rayos al nivel 11 y cuatro rayos al nivel 17. Puedes dirigir los rayos al mismo objetivo o a diferentes. Realiza una tirada de ataque y de tipo de daño separadas para cada rayo.

#### Arma Profana
*Evocación de nivel 5*
___
- **Tiempo de lanzamiento:** 1 acción adicional
- **Alcance:** Toque
- **Componentes:** V, S
- **Duración:** Concentración, hasta 1 hora
___
Imbuyes un arma que tocas con poder profano. Hasta que el hechizo termine, el arma crea un área de oscuridad en un radio de 9 metros y luz tenue en un radio adicional de 9 metros. El portador del arma profana es inmune a este efecto. Además, los ataques con arma realizados con ella infligen 2d8 de daño necrótico adicional en un golpe. Si el arma no es ya un arma mágica, se convierte en una para la duración.

Como acción adicional en tu turno, puedes disipar este hechizo y hacer que el arma emita un torrente de sombras corruptas. Cada criatura de tu elección que puedas ver en un radio de 9 metros del arma debe hacer una tirada de salvación de Constitución. Si falla, la criatura recibe 4d8 de daño necrótico y queda cegada durante 1 minuto. Si tiene éxito, recibe la mitad de daño y no queda cegada. Al final de cada uno de sus turnos, una criatura cegada puede hacer una tirada de salvación de Constitución, terminando el efecto sobre sí misma con un éxito.

<div class='footnote'>PARTE 2 | HECHIZOS</div>

\pagebreakNum

#### Vórtice de Ursol
*Conjuración de nivel 4*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** 18 metros
- **Componentes:** V, S
- **Duración:** Concentración, hasta 1 minuto
___
Elige un punto que puedas ver dentro del alcance. Una fuerza elemental que se asemeja a un vórtice giratorio se extiende en un radio de 3 metros desde el punto y dura mientras el hechizo permanezca activo.

El área se considera terreno difícil y cualquier criatura que entre o comience su turno en el vórtice debe hacer una tirada de salvación de Fuerza. Si falla, la criatura recibe 2d6 de daño contundente y es arrastrada hacia un espacio vacío cercano al centro del vórtice. Si tiene éxito, recibe la mitad del daño y no es arrastrada.

Como acción adicional, puedes mover el vórtice hasta 9 metros en cualquier dirección.

***A niveles superiores.*** Cuando lanzas este hechizo con un espacio de nivel 5 o superior, el daño aumenta en 1d6 por cada nivel de espacio por encima del 4.

\columnbreak

#### Cambio de Vacío
*Necromancia de 3er nivel*
___
- **Tiempo de lanzamiento:** 1 acción
- **Alcance:** 60 pies
- **Componentes:** V, S
- **Duración:** Instantánea
___
Invocas al vacío para intercambiar la salud tuya y de otra criatura. Elige una criatura dispuesta dentro del alcance; tú y la criatura elegida intercambian sus puntos de golpe actuales, hasta un máximo de 40 puntos de golpe de cada criatura. Este hechizo no tiene efecto en una criatura que esté incapacitada o con 0 puntos de golpe.

***A niveles superiores.*** Cuando lanzas este hechizo usando un espacio de conjuro de 5º nivel o superior, el máximo de puntos de golpe que puedes intercambiar aumenta en 10 por cada nivel de espacio por encima del 4º.

\pagebreakNum

# Capítulo 1: Razas Monstruosas
Los héroes vienen en muchas formas y tamaños; algunos de ellos han estado presentes desde tiempos antiguos en la faz de Azeroth, mientras que otros han emergido recientemente para ofrecer su ayuda. Este capítulo presenta razas de personajes que muchos considerarían monstruosas o directamente hostiles hacia miembros de cualquiera de las dos facciones.

Si eres el DM, incluir estas razas en tu campaña es una oportunidad narrativa, una chance para decidir qué roles juegan estas distintas razas en las historias que tejes.

Si eres un jugador, consulta con tu DM antes de usar cualquiera de estas razas. El DM puede aprobar o denegar tu elección de raza o subraza, o puede modificarla de alguna manera.

### Rasgos Raciales
Los rasgos de las razas monstruosas son inusuales en que algunas de ellas tienen una reducción en una puntuación de habilidad y otras son más o menos poderosas que las razas típicas de Azeroth, lo que ofrece razones adicionales para usarlas con precaución en una campaña.

Las siguientes razas se detallan en este capítulo:
<div style='margin-top:-5px;'></div>

&nbsp;&nbsp;&nbsp; **Furbolg.** guardianes del bosque que prefieren métodos pacíficos para proteger sus hogares, aunque tomarán las armas si es necesario.

**Gnoll.** una raza humanoide con aspecto de hiena simple pero feroz, impulsada profundamente por la vida en manada y que disfruta que otros hagan el trabajo duro por ellos.

**Arpía.** criaturas voladoras y despiadadas que anidan en lugares difíciles de alcanzar y matan a cualquier intruso en sus tierras.

**Kobold.** una raza diminuta que habita en cavernas y minas. No son considerados inteligentes según los estándares de la mayoría de las razas y son notoriamente cobardes.

**Mok'nathal.** híbridos nacidos de la unión entre orcos y ogros, marginados que rara vez son bienvenidos en ambos lados.

**Múrloc.** seres anfibios que habitan costas y riberas, profundamente territoriales y cuyos campamentos tribales inspiran miedo a los viajeros imprudentes.

**Naga.** híbridos del océano que sirven a su reina, Azshara, en su búsqueda de dominio sobre Azeroth.

**Jabaespín.** humanoides agresivos con rasgos de jabalí que viven en laberintos aislados de espinas y formaciones rocosas.

**Sátiro.** demonios bestiales y despiadados creados por una antigua maldición, nacidos para ser hechiceros al servicio de un mal mayor.

**Tortollano.** viajeros nómadas que deambulan por Azeroth, dedicados a explorar el mundo que los rodea.

<div class='footnote'>RAZAS MONSTRUOSAS</div>

<img src='https://i.ibb.co/86KR787/gnoll.png' style='position:absolute; top:90px; right:-300px; width:900px' />
<img src='https://www.gmbinder.com/images/E8GrMME.png' style='position:absolute; top:0px; right:-10px; width:900px' />
<img src='https://www.gmbinder.com/images/3e9S91s.png' style='position:absolute; top:-890px; right:0px; width:900px;' />

\pagebreakNum

#### Rasgos de los Furbolg

***Incremento de Caracteristica.*** Fuerza +2 y Sabiduría +1.

***Edad.*** Los furbolg alcanzan la adultez a los 30 años y pueden vivir hasta 250 años.

***Alineamiento.*** La sociedad furbolg se centra en su jefe y su comunidad, con leyes y estilos de vida bien establecidos. Los furbolg no sienten amor por la guerra y nunca se apresuran a luchar, lo que los inclina hacia la neutralidad.

***Tamaño.*** Los furbolg miden entre 2,1 y 2,7 metros y pesan entre 140 y 165 kilogramos. Tu tamaño es mediano.

***Velocidad.*** 9 metros.

***Vision en la Oscuridad.*** Puedes ver en luz tenue en un radio de 18 metros como si fuera luz brillante, y en oscuridad como si fuera luz tenue. No puedes distinguir colores en la oscuridad, solo tonos de gris.

***Favor del Poderoso y Sabio.*** Conoces el truco *druidismo*. Puedes lanzar *mejorar habilidad* con este rasgo sin proporcionar componentes materiales, usando Sabiduría como tu habilidad de lanzamiento. Una vez que hayas lanzado este hechizo, no puedes volver a hacerlo con este rasgo hasta que termines un descanso largo.

***Garras.*** Tus garras son armas naturales que puedes usar para hacer ataques sin armas. Si golpeas con ellas, infliges daño cortante igual a 2d4 + tu modificador de Fuerza, en lugar del daño contundente normal de un golpe sin armas.

***Armadura Natural.*** Cuando no llevas armadura, tu CA es 12 + Mod. Destreza. Los beneficios de un escudo se aplican con normalidad mientras usas tu armadura natural.

***Construccion Poderosa.*** Se te considera de un tamaño más grande al determinar tu capacidad de carga y el peso que puedes empujar, arrastrar o levantar.

***Idiomas.*** Puedes hablar, leer y escribir darnassiano y ursino. El ursino es el idioma nativo de los furbolg, que combina partes de la lengua darnassiana con gruñidos y rugidos diversos.

#### Rasgos de los Gnolls

***Incremento de Caracteristica.*** Fuerza +2, Destreza +1 y Inteligencia -1.

***Edad.*** Los gnolls alcanzan la adultez a los 4 años y pueden vivir hasta 20 años, aunque rara vez lo hacen.

***Alineamiento.*** Los gnolls son criaturas impredecibles que viven en sociedades tribales donde prevalecen los más fuertes. No son conocidos por ser compasivos, ni siquiera con los suyos. Tienden hacia el caos y el mal.

***Tamaño.*** Los gnolls miden entre 1,5 y 1,8 metros y pesan entre 68 y 90 kilogramos. Tu tamaño es mediano.

***Velocidad.*** 9 metros.

***Vision en la Oscuridad.*** Puedes ver en luz tenue en un radio de 18 metros como si fuera luz brillante, y en oscuridad como si fuera luz tenue. No puedes distinguir colores en la oscuridad, solo tonos de gris.

***Mordida.*** Tu mordida es un arma natural que puedes usar para hacer ataques sin armas. Si golpeas con ella, infliges daño perforante igual a 1d4 + Mod. Fuerza, en lugar del daño contundente normal de un golpe sin armas.

***Entrenamiento de Guerra Gnoll.*** Competencia con cimitarra, gran garrote, ballesta ligera y ballesta pesada.

***Olfato Agudo.*** Competencia en Percepción, y ventaja en las pruebas de Sabiduría (Percepción) que dependan del olfato.

&nbsp;&nbsp;***Ultimo Aliento.*** Cuando te reduzcan a 0 puntos de golpe pero no te maten al instante, puedes usar tu reacción para realizar un ataque de mordida antes de caer inconsciente.

***Hambre Incontrolable.*** Mientras estés a la vista de una criatura que no tenga sus puntos de golpe máximos, puedes tomar la acción de Correr como acción adicional y moverte hacia esa criatura.

***Idiomas.*** Puedes hablar común básico y gnoll. El gnoll no tiene escritura; el idioma se compone de diferentes ladridos utilizados dentro de la tribu gnoll. El dialecto de una tribu gnoll puede diferir del de otra.

<div style='margin-top:-6px;'></div>

#### Rasgos de la Arpía
***Incremento de Caracteristica.*** Destreza +2 y Sabiduría +1.

***Edad.*** Las arpías alcanzan la adultez a los 20 años y pueden vivir hasta 80 años.

***Alineamiento.*** Las arpías son caóticas por naturaleza. Sus sociedades tienen estructura, pero existen pocas leyes más allá de la supervivencia. Tienden a ser malvadas, con disposición a atraer y engañar a otras razas para su propio beneficio.

***Tamano.*** Las arpías miden entre 1,5 y 1,8 metros y pesan entre 34 y 45 kilogramos. Tu tamaño es mediano.

***Velocidad.*** 7,5 metros.

***Vuelo.*** Tienes una velocidad de vuelo de 12 metros. Para usar esta velocidad, no puedes llevar armadura media o pesada.

***Vision en la Oscuridad.*** Puedes ver en luz tenue en un radio de 18 metros como si fuera luz brillante, y en oscuridad como si fuera luz tenue. No puedes distinguir colores en la oscuridad, solo tonos de gris.

***Ataque en Picado.*** Si desciendes al menos 6 metros hacia una criatura y la golpeas con un ataque en tu primer turno de combate, el ataque inflige 2d6 puntos de daño adicional. Solo puedes usar este rasgo una vez por combate.

***Grito Incapacitante.*** Puedes usar tu acción para emitir un chillido horrendo. Cada criatura en un radio de 4,5 metros que pueda oírte debe hacer una tirada de salvación de Constitución (CD 8 + tu bonificación de competencia + tu modificador de Sabiduría), o quedar incapacitada hasta el final de tu próximo turno. No puedes volver a usar esta característica hasta que termines un descanso largo.

***Idiomas.*** Puedes hablar, leer y escribir darnassiano y común básico.

<div style='margin-top:-6px;'></div>

\pagebreakNum

#### Rasgos del Kobold

***Incremento de Caracteristica.*** Destreza +2, Constitución +1 y Carisma -2.

***Edad.*** Los kobolds alcanzan la adultez a los 6 años y pueden vivir hasta 60 años.

***Alineamiento.*** Los kobolds son criaturas huidizas que habitan en las profundidades de Azeroth. No son intrínsecamente malvados, pero sí excepcionalmente territoriales. Tienden hacia el caos y la neutralidad.

***Tamano.*** Los kobolds miden entre 60 y 90 centímetros y pesan entre 11 y 16 kilogramos. Tu tamaño es pequeño.

***Velocidad.*** 9 metros.

***Oscuridad Consumidora.*** Siempre que comiences tu turno en un área de oscuridad, debes superar una tirada de salvación de Sabiduría CD 10 o quedar aterrorizado de la oscuridad hasta el inicio de tu siguiente turno. Debes usar tu movimiento para moverte hacia una fuente de luz tenue o brillante, si hay alguna.

***Escapista Ágil.*** Puedes tomar la acción de Desenganche o Esconderse como acción adicional en cada uno de tus turnos.

***Tácticas de Manada.*** Tienes ventaja en una tirada de ataque contra una criatura si al menos uno de tus aliados está a 1,5 metros de la criatura y el aliado no está incapacitado.

***Idiomas.*** Puedes hablar común básico.

\columnbreak

#### Rasgos de Mok'nathal

***Mejora de Caracteristica.*** Fuerza +2, Constitución +2 y Destreza -1.

***Edad.*** Los mok'nathal maduran al mismo ritmo que los humanos, alcanzando la adultez en la adolescencia tardía. Sin embargo, al igual que los orcos, envejecen más rápido y rara vez viven más de un siglo.

***Alineamiento.*** Los mok'nathal han heredado la naturaleza caótica de sus antepasados, aunque tienden hacia un carácter más apacible. No obstante, son mucho más comedidos que los ogros y suelen inclinarse más hacia la neutralidad que al mal.

***Tamano.*** Los mok'nathal miden entre 8 y 10 pies de altura y pesan entre 350 y 400 libras. Tu tamaño es mediano, aunque superas en altura a la mayoría de los humanoides.

***Velocidad.*** 30 pies.

***Vision en la Oscuridad.*** Puedes ver en luz tenue en un radio de 60 pies como si fuera luz brillante y en oscuridad como si fuera luz tenue. No puedes distinguir colores en la oscuridad, solo tonos de gris.

***Intimidante.*** Estás entrenado en la habilidad de Intimidación. Tienes ventaja en las pruebas de Intimidación que usen Fuerza.

***Armadura Natural.*** Cuando no lleves armadura, tu CA es 11 + tu modificador de Destreza. Los beneficios de un escudo se aplican de manera normal mientras usas tu armadura natural.

***Punos de Ogro.*** Tu puño cerrado es capaz de realizar un ataque desarmado impactante. Si golpeas con él, infliges 1d6 + tu modificador de Fuerza en daño contundente.

***Construccion Poderosa.*** Se te considera una criatura de un tamaño mayor al determinar tu capacidad de carga y el peso que puedes empujar, arrastrar o levantar.

***Resistencia Implacable.*** Cuando te reduzcan a 0 puntos de golpe pero no te maten, puedes caer a 1 punto de vida en su lugar. Debes finalizar un descanso largo para usar esta característica nuevamente.

***Idiomas.*** Puedes hablar, leer y escribir Común, Bajo Común y Orco. La mayoría de los mok'nathal son capaces de hablar el idioma de ambos padres, aunque rara vez tengan oportunidad de usarlo.

<div class='footnote'>RAZAS MONSTRUOSAS</div>

\pagebreakNum

#### Rasgos de Múrloc

***Incremento de Caracteristica.*** Destreza +2 y Sabiduría +1.

***Edad.*** Los múrlocs alcanzan la adultez a los 12 años y viven hasta <br> 65 años.

***Alineamiento.*** Los múrlocs son fundamentalmente neutrales; se defienden a sí mismos y su territorio si es necesario, confiando en la fuerza de su número más que en el múrloc individual. Muchos múrlocs también tienden hacia el mal.

***Tamano.*** Los múrlocs miden entre 3 y 5 pies de altura y pesan entre 30 y 50 libras. Tu tamaño es Pequeño.

***Velocidad.*** 25 pies, y tienes una velocidad de nado de 25 pies.

***Vision en la Oscuridad.*** Puedes ver en luz tenue en un radio de 60 pies <br> como si fuera luz brillante y en oscuridad como si fuera luz <br> tenue. No puedes distinguir colores en la oscuridad, solo tonos de gris.

***Anfibio.*** Puedes respirar aire y agua.

***Mordisco.*** Tu mordida es un arma natural que puedes usar para realizar ataques desarmados. Si golpeas con ella, infliges daño perforante igual a 1d4 + tu modificador de Fuerza, en lugar del daño contundente normal de un ataque desarmado.

***Tacticas de Grupo.*** Tienes ventaja en una tirada de ataque contra una criatura si al menos uno de tus aliados está a 5 pies de la criatura y no está incapacitado.

***Escurridizo.*** Tienes ventaja en las pruebas de habilidad y tiradas de salvación para escapar de un agarre.

***Idiomas.*** Puedes hablar Nerglish. Nerglish es el lenguaje gutural de los múrlocs, una lengua incomprensible para otras razas y criaturas.

> ##### Variante de Naga: Cuatro Brazos
> Puedes añadir el siguiente rasgo a tu naga, reemplazando los beneficios de tu Cola Serpentina.
>
> ***Cuatro Brazos.*** Tienes cuatro brazos en lugar de dos. Tus brazos y manos son igualmente hábiles. Cada brazo puede sostener un objeto o arma, y realizar las siguientes tareas simples: levantar, soltar, sostener, empujar o tirar de un objeto; hacer un ataque con arma; realizar componentes somáticos de hechizos; o sujetar a alguien.
>
> Tus brazos adicionales te permiten realizar una interacción adicional con objetos en cada uno de tus turnos.
>
> Si realizas un ataque con un arma usando dos manos o si usas combate con dos armas, no obtienes beneficios de sostener un escudo hasta el inicio de tu próximo turno.

\columnbreak

#### Rasgos de Naga

***Incremento de Caracteristica.*** Destreza +1, y Fuerza o Inteligencia +2.

***Edad.*** Los nagas maduran al mismo ritmo que los elfos de la noche y tienen una esperanza de vida similar a la suya.

***Alineamiento.*** Los nagas estructuran sus sociedades por rangos y son siempre legales. Aquellos que siguen el mandato de la Reina Azshara tienden a ser malvados, mientras que los nagas que se alejan de Azshara y su imperio suelen ser neutrales.

***Tamano.*** Los nagas miden entre 12 y 15 pies de longitud, alcanzando una altura promedio de 7 pies y pesando entre 250 y 400 libras. Tu tamaño es Mediano.

***Velocidad.*** 25 pies, y tienes una velocidad de nado de 40 pies.

***Vision en la Oscuridad.*** Puedes ver en luz tenue en un radio de 60 pies <br> como si fuera luz brillante y en oscuridad como si fuera luz <br> tenue. No puedes distinguir colores en la oscuridad, solo tonos de gris.

***Anfibio.*** Puedes respirar aire y agua.

***Criatura del Mar.*** Puedes comunicar ideas simples a las bestias que puedan respirar agua. Ellas entienden el significado de tus palabras, aunque no tienes una habilidad especial para entenderlas de vuelta.

***Explorador de las Profundidades.*** Ignoras cualquier desventaja causada por un entorno submarino profundo.

***Armadura Natural.*** Cuando no lleves armadura, tu CA es 12 + Mod. Destreza. Los beneficios de un escudo se aplican de manera normal mientras usas tu armadura natural.

***Cola Serpentina.*** Puedes agarrar cosas con tu cola. Tiene un alcance de 5 pies y puede levantar un número de libras igual a cinco veces tu puntuación de Fuerza. Puedes usarla para realizar las siguientes tareas simples: levantar, soltar, sostener, empujar o arrastrar un objeto o criatura; atrapar a alguien; o realizar ataques desarmados. Tu DM podría permitir que se añadan otras tareas simples a esta lista de opciones.

Tu cola serpentina no puede empuñar armas ni escudos, ni <br> realizar tareas que requieran precisión manual, como usar herramientas, objetos mágicos o ejecutar los componentes somáticos de un hechizo.

***Idiomas.*** Puedes hablar, leer y escribir Común y Nazja. El Nazja deriva del idioma Darnassiano y utiliza la escritura de los elfos de la noche, aunque ahí terminan las similitudes entre ambos idiomas.


<div class='footnote'>Razas montruosas</div>

\pagebreakNum


#### Rasgos de los Jabaespines

***Incremento de Caracteristica.*** Constitución +2, Destreza +1, y Carisma -2.

***Edad.*** Los jabaespines alcanzan la adultez a los 3 años y pueden vivir hasta 50 años.

***Alineamiento.*** Los jabaespines viven en tribus esparcidas por Los Baldíos de Kalimdor. Respetan a quienes recorren las llanuras, pero no dudan en luchar si se sienten amenazados. Suelen ser de alineamiento maligno neutral.

***Tamano.*** Los jabaespines miden entre 1,5 y 1,8 metros y pesan entre 90 y 115 kilogramos. Tu tamaño es mediano.

***Velocidad.*** 9 metros.

***Vision en la Oscuridad.*** Puedes ver en luz tenue en un radio de 18 metros como si fuera luz brillante, y en oscuridad como si fuera luz tenue. No puedes distinguir colores en la oscuridad, solo tonos de gris.

***Olfato Agudo.*** Competencia en Percepción y ventaja en las pruebas de Sabiduría (Percepción) que dependan del olfato.

***Puas.*** Cuando te golpeen con un ataque cuerpo a cuerpo, puedes usar tu reacción para lanzar púas al atacante. El objetivo debe realizar una tirada de salvación de Destreza (CD 8 + tu bonificador de competencia + tu modificador de Destreza), recibiendo daño perforante igual a 1d6 + tu nivel si falla la tirada, o la mitad de daño si tiene éxito.

Una vez que usas este rasgo, no puedes volver a usarlo hasta que termines un descanso corto o largo.

***Venganza.*** Puedes realizar un ataque de oportunidad con desventaja contra un objetivo dentro de tu alcance cuando una criatura aliada que puedas ver cae inconsciente.

***Idiomas.*** Puedes hablar, leer y escribir Común y Jabaespín. El jabaespín es un idioma que combina gruñidos y bufidos para transmitir distintos mensajes.

#### Rasgos de los Sátiros

***Incremento de Caracteristica.*** Carisma +2, y Destreza +1.

***Edad.*** Los sátiros alcanzan la adultez a los 50 años y pueden vivir miles de años.

***Alineamiento.*** Los sátiros portan la corrupción vil y la marca del Titán Oscuro Sargeras; son embaucadores y tramposos que buscan su propio beneficio. Tienden al caos maligno, aunque aquellos que se distancian de la Legión Ardiente suelen ser malignos neutrales.

***Tamano.*** Los sátiros miden entre 2,1 y 2,7 metros y pesan entre 90 y 125 kilogramos. Tu tamaño es mediano.

***Velocidad.*** 9 metros.

***Vision en la Oscuridad.*** Puedes ver en luz tenue en un radio de 18 metros como si fuera luz brillante, y en oscuridad como si fuera luz tenue. No puedes distinguir colores en la oscuridad, solo tonos de gris.

***Garras.*** Tus garras son armas naturales que puedes usar para realizar ataques sin armas. Si golpeas con ellas, infliges daño cortante igual a 1d4 + tu modificador de Fuerza, en lugar del daño contundente normal de un golpe sin armas.

***Naturaleza Enganosa.*** Ganas competencia en dos de las siguientes habilidades a tu elección: Engaño, Percepción, Interpretación, Sigilo o Supervivencia.

***Sombra Oculta.*** Puedes intentar esconderte incluso cuando solo estés ligeramente oculto por follaje, lluvia intensa, nieve cayendo, niebla u otros fenómenos naturales.

***Entrenamiento de Armas de satiro.*** Competencia con la daga, el cimitarra y el arco corto.

***Idiomas.*** Puedes hablar, leer y escribir Común y Darnassiano.

#### Rasgos de los Tortollan

***Incremento de Caracteristica.*** Sabiduría +2, y Carisma +1.

***Edad.*** Los tortollan alcanzan la adultez a los 14 años y pueden vivir hasta 700 años.

***Alineamiento.*** Los tortollan tienden a llevar vidas ordenadas y ritualistas. Desarrollan costumbres y rutinas, volviéndose más rígidos con la edad. La mayoría son de alineamiento bueno y legal. Algunos pueden ser egoístas y codiciosos, inclinándose más hacia el mal, pero es raro que un tortollan abandone el orden en favor del caos.

***Tamano.*** Los tortollan miden entre 1,8 y 2,1 metros y pesan entre 180 y 205 kilogramos. Su caparazón representa aproximadamente un tercio de su peso. Tu tamaño es mediano.

***Velocidad.*** 7,5 metros, y tienes una velocidad de nado de 7,5 metros.

***Anfibio.*** Puedes respirar aire y agua.

***Mordida.*** Tu mandíbula con colmillos es un arma natural que puedes usar para realizar ataques sin armas. Si golpeas con ella, infliges daño perforante igual a 1d4 + tu modificador de Fuerza, en lugar del daño contundente normal de un golpe sin armas.

***Armadura Natural.*** Debido a tu caparazón y la forma de tu cuerpo, no eres apto para llevar armadura. Sin embargo, tu caparazón te proporciona suficiente protección; te otorga una CA base de 17 (tu modificador de Destreza no afecta este número). No obtienes beneficios de llevar armadura, pero si usas un escudo, puedes aplicar el bono del escudo con normalidad.

***Narrador.*** Ganas competencia en la habilidad de Historia.

***Escuchar un Rato.*** Puedes usar un pergamino de conjuro con un tiempo de lanzamiento de una acción como una acción adicional. No puedes usar esta característica de nuevo hasta que termines un descanso corto o largo.

***El Mundo en mi Espalda.*** Tu caparazón funciona como una mochila y puede contener hasta 18 kilogramos de equipo; también puedes sujetar objetos al exterior. Para que un objeto quede detrás en tu caparazón, debe ser más pequeño que 30 centímetros cúbicos. Tu velocidad no se reduce por el equipo almacenado dentro de tu caparazón.

***Idiomas.*** Puedes hablar, leer y escribir Común y otros dos idiomas de tu elección. Los tortollan no tienen un idioma propio, pero disfrutan aprender otros idiomas; son excepcionales narradores y aman escuchar y contar historias de otras razas.

<div class='footnote'>RAZAS MONSTRUOSAS</div>

\pagebreakNum

<div class='partpage'>

# Parte III
##### Reglas adicionales
</div>

<style> .phb#p142:after { display:none; } </style>
<img src='https://www.gmbinder.com/images/X9qkkqr.jpg' style='position:absolute; top:0px; right:-460px; width:1700px' />

\pagebreak

# Puntos de Héroe
Un paladín que se enfrenta solo a una horda de no-muertos mientras sus compañeros sanan a un camarada moribundo, un pícaro que salta tras un artefacto valioso caído desde un alto balcón, un guerrero que se lanza contra un oponente mucho más fuerte... Estos son los héroes cuyas acciones inspiran historias y leyendas.

Las acciones de un héroe a menudo incluyen hazañas de naturaleza tan audaz que es casi imposible garantizar un resultado seguro. Aunque todo héroe enfrenta peligros, el destino favorece a quienes enfrentan la adversidad de frente, desafiando al mal y la oscuridad sin temor a la muerte.

En lugar de obtener inspiración mientras exploran el mundo de Warcraft, los jugadores pueden recibir Puntos de Héroe por sus actos valientes contra enemigos poderosos.

Los puntos de héroe son recompensas por este tipo de acciones valerosas; estos puntos permiten al jugador inclinar la suerte a favor de su personaje, y tal poder requiere una gestión más directa del DM que otras reglas. Los puntos de héroe difuminan los límites de la acción, permitiendo a los personajes realizar lo excepcional e incluso lo imposible.

### Ganar Puntos de Héroe
El poder otorgado por los puntos de héroe puede ser inmenso. Tu DM puede concederte un punto de héroe por tus actos heroicos. Algunos aventureros tal vez nunca ganen un punto de héroe, y cuando lo hacen, no hay garantía de que el jugador lo use en el momento adecuado. Tu DM te dirá cómo puedes ganar un punto de héroe durante el juego.

Tienes un punto de héroe o no tienes ninguno; no puedes acumular múltiples "puntos de héroe" para uso posterior. Del mismo modo, no puedes ganar un punto de héroe a través de una acción para la cual gastaste un punto de héroe.

### Usar Puntos de Héroe
Si tienes un punto de héroe, puedes gastarlo al realizar una tirada de ataque, lanzar un hechizo, una tirada de salvación o al ser atacado. Gastar tu punto de héroe hace que la prueba sea un éxito inmediato.

#### Impulso de Acción
Puedes gastar tu punto de héroe para tomar tu próximo turno fuera del orden de iniciativa. Una vez que termines tu turno, la iniciativa regresa a la normalidad y vuelves a tu lugar en el conteo.

#### Luchador Físico
Puedes gastar tu punto de héroe al realizar una tirada de ataque con un arma, considerándola como un golpe exitoso. Al hacerlo, el jugador elige uno de los siguientes efectos:

**Golpe Poderoso.** Tu ataque actúa como un Golpe Crítico Masivo, tirando dos veces los dados de daño del ataque y sumando los resultados. Luego añade cualquier modificador relevante como de costumbre y suma tu nivel de personaje al daño.

&nbsp;&nbsp;&nbsp; **Mutilar.** Tu ataque mutila al objetivo, infligiendo daño normal y tratando de cortar un miembro (si lo tiene) a tu elección. La criatura debe superar una tirada de salvación de Constitución o perder el miembro elegido. La CD es igual a 10 o la mitad del daño infligido.

 - ***Brazo / Mano.*** Cortas el brazo de la criatura, impidiéndole sostener dos objetos a la vez o lanzar hechizos si su brazo restante sostiene un objeto.
 - ***Pierna / Pie.*** Cortas la pierna de la criatura, reduciendo su velocidad de movimiento a la mitad y otorgando ventaja en los ataques de oportunidad contra ella. Además, no puede usar la acción de correr.
 - ***Ojo.*** Perforas el ojo de la criatura, dándole desventaja en pruebas de Percepción y reduciendo su Percepción pasiva en 5. Si pierde ambos ojos o solo tiene uno, se considera Cegada. Esta mutilación no tiene efecto si el daño es contundente.

#### Luchador Mágico
Puedes gastar tu punto de héroe al lanzar un hechizo, considerándolo como un impacto exitoso. Al hacerlo, el jugador elige uno de los siguientes efectos:

**Sobrecarga.** Tu ataque mágico actúa como un Golpe Crítico Masivo, tirando dos veces los dados de daño del ataque y sumando los resultados. Luego añade cualquier modificador relevante y suma tu nivel de personaje al daño.

**Hechizo Preciso.** Puedes elegir un número de criaturas igual a tu modificador de habilidad de lanzamiento para que automáticamente tengan éxito o fallen una tirada de salvación contra tu hechizo.

#### Defensa
Puedes gastar tu punto de héroe cuando eres objetivo de un ataque o hechizo. Al hacerlo, el jugador elige uno de los siguientes efectos:

**Esquiva.** Un ataque que puedas ver automáticamente falla, sin importar la tirada.

**Resistente.** Tienes éxito en tu tirada de salvación y obtienes los efectos de la *evasión* de los pícaros hasta el final del turno actual.

#### Sobreviviente
Puedes gastar tu punto de héroe tras fallar una tirada de salvación por muerte o al sufrir un daño masivo, cambiando tu salud a 0 y estabilizándote.

A discreción del DM, puedes sufrir una herida distintiva (una cicatriz, ojo perdido, cojera, etc.) como recordatorio de que los puntos de héroe no siempre te salvarán.

#### Experto Innato
Puedes gastar un punto de héroe antes o después de realizar una prueba de habilidad, convirtiendo el resultado en un 20 natural. Los puntos de héroe no pueden usarse para cambiar el resultado de pruebas de habilidad basadas en Inteligencia, Sabiduría o Carisma.

Los puntos de héroe son una explosión de energía o fuerza; no hacen que alguien sea repentinamente más carismático o le otorgan conocimiento de la vasta biblioteca de Dalaran.

<div class='footnote'>PARTE 3 | REGLAS VARIANTES</div>

\pagebreakNum

# Maná
Con esta regla adicional, un personaje que posee la característica de Lanzamiento de Conjuros usa maná en lugar de espacios de conjuro para lanzar hechizos. El maná otorga al lanzador más flexibilidad, aunque a costa de una mayor complejidad.
<br>&nbsp;&nbsp;&nbsp; En esta variante, cada hechizo tiene un coste de maná basado en su nivel. La tabla de Coste de Maná resume el coste en maná de los espacios de 1º a 9º nivel. Los trucos no requieren espacios y, por tanto, no consumen maná.

En lugar de obtener espacios de conjuro para lanzar hechizos, obtienes una reserva de maná. Puedes gastar puntos de maná para crear un espacio de conjuro de un nivel específico y usarlo para lanzar un hechizo. No puedes reducir tu maná por debajo de 0 y recuperas todo el maná al finalizar un descanso largo.

Los hechizos de nivel 6º o superior son agotadores. Puedes crear un espacio de conjuro de esos niveles con maná, pero no puedes crear otro del mismo nivel hasta que termines un descanso largo.

El maná que puedes gastar depende de tu nivel de lanzador de conjuros, como se muestra en la tabla de Maná por Nivel. Tu nivel también determina el nivel máximo de espacio de conjuro que puedes crear. Aunque tengas suficiente maná, no puedes crear un espacio por encima de ese límite.

La tabla de Maná por Nivel se aplica a druidas, magos, sacerdotes y chamanes. Para caballeros de la muerte, druidas (ferales) o paladines, divide a la mitad el nivel del personaje en esa clase y luego consulta la tabla.

Este sistema puede aplicarse a monstruos que lancen conjuros usando espacios de conjuro, aunque no se recomienda debido a la dificultad de hacer un seguimiento del gasto de maná.

##### Coste de Maná
<div style='column-count:2'>

| Nivel del Hechizo | Coste de Maná |
|:---:|:-:|
| 1  | 2  |
| 2  | 3  |
| 3  | 5  |
| 4  | 6  |

| Nivel del Hechizo | Coste de Maná |
|:---:|:--:|
| 5  |  7  |
| 6  |  9  |
| 7  | 10  |
| 8  | 11  |
| 9  | 13  |
</div>

\columnbreak

<div style='margin-top:100px;'></div>

<div class='classTable'>

##### Maná por Nivel
| Nivel de Clase | Maná | Nivel Máx. Hechizo |
|:---:|:---:|:-:|
|  1  |   3 |1  |
|  2  |   6 |1  |
|  3  |  14 |2  |
|  4  |  17 |2  |
|  5  |  27 |3  |
|  6  |  32 |3  |
|  7  |  38 |4  |
|  8  |  44 |4  |
|  9  |  57 |5  |
| 10  |  64 |5  |
| 11  |  73 |6  |
| 12  |  73 |6  |
| 13  |  83 |7  |
| 14  |  83 |7  |
| 15  |  94 |8  |
| 16  |  94 |8  |
| 17  | 107 |9  |
| 18  | 114 |9  |
| 19  | 123 |9  |
| 20  | 133 |9  |
</div>

<div class='footnote'>PARTE 3 | REGLAS VARIANTES</div>
<img src='https://www.gmbinder.com/images/yrSnqwW.jpg' style='position:absolute; top:750px; right:-75px; width:950px' />
<img src='https://www.gmbinder.com/images/L60ii4e.png' style='position:absolute; top:20px; right:0px; width:900px' />
<img src='https://www.gmbinder.com/images/fZMAlU8.png' style='position:absolute; top:30px; right:72px; width:300px' />]====]

local function EscapePattern(value)
    return tostring(value or ""):gsub("([^%w])", "%%%1")
end

local function CleanMarkdown(value, rich)
    value = tostring(value or "")
    value = value:gsub("\r", "")
    -- Bloques <style>...</style> completos (su CSS dejaba numeros sueltos en el texto).
    value = value:gsub("<style.->.-</style>", "")
    -- Pies de pagina del manual: <div class='footnote'>CLASES | MAGO</div> (contenido incluido).
    value = value:gsub("<div[^>]-footnote.->.-</div>", "")
    -- Restos de pie tipo "CLASES | MAGO" / "RAZAS | HUMANO" sueltos (linea en mayusculas con |).
    value = value:gsub("\n%u[%u%s]+|[%u%s]+", "")
    value = value:gsub("<br%s*/?>", "\n")
    value = value:gsub("<[^>]->", "")                 -- resto de etiquetas HTML (incl. <div>, <img>, <span>)
    -- Directivas de maquetacion GMbinder/LaTeX (\columnbreak, \pagebreak, \pagebreakNum, \column, ...).
    value = value:gsub("\\%a+", "")
    value = value:gsub("{{%S*%s*", "")                -- apertura de bloque GMbinder {{tag
    value = value:gsub("}}", "")
    value = value:gsub("!%b[]%b()", "")               -- imagenes ![alt](url)
    value = value:gsub("%[([^%]]*)%]%b()", "%1")      -- enlaces [texto](url) -> texto
    value = value:gsub("\n[ \t]*|[^\n]*", "")         -- filas de tabla que EMPIEZAN por | (raras)
    -- Tablas GMbinder normales: `celda|celda`, SIN pipe inicial ("Nivel de Conjuro|Conjuros",
    -- "1.º|vacío oscuro, ..."). El gsub de arriba no las tocaba y la tabla entera salia cruda
    -- en el About (Conjuros Ampliados de Afliccion). La fila separadora (----|----) se elimina
    -- y cada fila de datos se vuelve texto plano "izquierda: derecha".
    value = value:gsub("[^\n]*|[^\n]*", function(linea)
        if linea:match("^[%s%-|:]+$") then return "" end
        return (linea:gsub("%s*|%s*", ": "))
    end)
    value = value:gsub("%^[^%^\n]+%^", "")            -- marcadores de fuente ^XGE^ del manual
    value = value:gsub("\226\156\166%s*", "")         -- adorno ✦ (sale como cuadro en el cliente)
    -- Sub-encabezados: en modo rich (About) se convierten a {h3} (titulos secundarios); en plano
    -- (tooltips) se quita el marcador y queda como linea de texto.
    -- Blockquote ANTES de los headings: en el manual hay lineas "> #### Titulo"; si se quitara el
    -- heading primero, el "> " dejaria el "####" a media linea sin convertir.
    value = value:gsub("\n>%s?", "\n")
    value = value:gsub("^>%s?", "")
    if rich then
        value = value:gsub("\n#+%s*([^\n]+)", "\n{h3}%1{/h3}")
        value = value:gsub("^#+%s*([^\n]+)", "{h3}%1{/h3}")
    else
        value = value:gsub("\n#+%s*", "\n")
        value = value:gsub("^#+%s*", "")
    end
    value = value:gsub("%*%*%*", "")
    value = value:gsub("%*%*", "")
    value = value:gsub("%*", "")
    value = value:gsub("`", "")
    value = value:gsub("&nbsp;", " ")
    value = value:gsub("&amp;", "&"):gsub("&lt;", "<"):gsub("&gt;", ">")
    value = value:gsub("\n%s*\n%s*\n+", "\n\n")
    value = value:gsub("^[ \t]+", "")
    value = value:gsub("[ \t]+\n", "\n")
    return value:match("^%s*(.-)%s*$") or ""
end

local function FindHeading(title, level, startAt)
    local hashes = string.rep("#", tonumber(level) or 3)
    local marker = "\n" .. hashes .. " " .. EscapePattern(title)
    local from, to = SOURCE:find(marker, startAt or 1)
    if not from and (startAt or 1) == 1 then
        from, to = SOURCE:find("^" .. hashes .. " " .. EscapePattern(title))
    end
    return from, to
end

local function FindNextHeading(startAt, maximumLevel)
    local searchAt = startAt or 1
    while true do
        local from, to, hashes = SOURCE:find("\n(#+)%s", searchAt)
        if not from then return nil end
        if #hashes <= maximumLevel then return from end
        searchAt = to + 1
    end
end

function API.GetSection(title, level, startAt)
    local from, to = FindHeading(title, level, startAt)
    if not from then return nil end
    local bodyStart = SOURCE:find("\n", to + 1) or (#SOURCE + 1)
    local nextHeading = FindNextHeading(bodyStart + 1, tonumber(level) or 3)
    local bodyEnd = nextHeading and (nextHeading - 1) or #SOURCE
    local text = CleanMarkdown(SOURCE:sub(bodyStart, bodyEnd))
    return text ~= "" and text or nil, bodyStart, bodyEnd
end

function API.GetNestedSection(parentTitle, parentLevel, title, level)
    local _, parentStart, parentEnd = API.GetSection(parentTitle, parentLevel)
    if not parentStart then return nil end
    local from, to = FindHeading(title, level, parentStart)
    if not from or from > parentEnd then return nil end
    local bodyStart = SOURCE:find("\n", to + 1) or (#SOURCE + 1)
    local nextHeading = FindNextHeading(bodyStart + 1, tonumber(level) or 3)
    local bodyEnd = math.min(nextHeading and (nextHeading - 1) or #SOURCE, parentEnd)
    local text = CleanMarkdown(SOURCE:sub(bodyStart, bodyEnd))
    return text ~= "" and text or nil
end

local function NormalizeHeading(value)
    value = tostring(value or "")
    if HarfordClassColors and HarfordClassColors.StripAccents then
        value = HarfordClassColors.StripAccents(value)
    end
    value = value:lower():gsub("[^%w]+", " ")
    return value:match("^%s*(.-)%s*$") or ""
end

function API.GetNestedSectionMatching(parentTitle, parentLevel, title, level)
    local _, parentStart, parentEnd = API.GetSection(parentTitle, parentLevel)
    if not parentStart then return nil end
    local wanted = NormalizeHeading(title)
    local searchAt = parentStart
    while true do
        local from, to, hashes, heading = SOURCE:find("\n(#+)%s*([^\n]+)", searchAt)
        if not from or from > parentEnd then return nil end
        if #hashes == (tonumber(level) or 3) and NormalizeHeading(heading) == wanted then
            local bodyStart = SOURCE:find("\n", to + 1) or (#SOURCE + 1)
            local nextHeading = FindNextHeading(bodyStart + 1, #hashes)
            local bodyEnd = math.min(nextHeading and (nextHeading - 1) or #SOURCE, parentEnd)
            local text = CleanMarkdown(SOURCE:sub(bodyStart, bodyEnd))
            return text ~= "" and text or nil
        end
        searchAt = to + 1
    end
end

function API.GetSource()
    return SOURCE
end

-- Los rasgos mecanicos del manual viven bajo "## Rasgos de Clase" (nivel 2) DENTRO del capitulo de
-- cada clase, no bajo "## <Clase>". La busqueda por seccion simple corta en "## Rasgos de Clase" y no
-- los alcanza. Esta funcion abarca TODO el capitulo (de "## <Clase>" hasta la siguiente CLASE) y busca
-- el rasgo como heading nivel 3/4 ahi dentro, con match normalizado (tolera tildes/mayusculas).
local function ClassNameSet()
    local set = {}
    if HarfordDnDBook and HarfordDnDBook.GetClasses then
        for _, c in ipairs(HarfordDnDBook.GetClasses() or {}) do
            if c and c.name then set[NormalizeHeading(c.name)] = true end
        end
    end
    return set
end

function API.GetClassChapterFeature(className, title, level, rich)
    local wantClass = NormalizeHeading(className)
    if wantClass == "" then return nil end
    local classNames = ClassNameSet()
    local level2Hashes = 2
    -- localizar el capitulo: "## <Clase>" y su fin en la siguiente clase (otro "## <clase conocida>")
    local start, chapterEnd, at = nil, nil, 1
    while true do
        local from, to, hashes, heading = SOURCE:find("\n(#+)%s*([^\n]+)", at)
        if not from then break end
        if #hashes == level2Hashes then
            local nh = NormalizeHeading((heading:gsub("<[^>]*>", "")))
            if not start and nh == wantClass then
                start = to
            elseif start and nh ~= wantClass and classNames[nh] then
                chapterEnd = from
                break
            end
        end
        at = to + 1
    end
    if not start then return nil end
    chapterEnd = chapterEnd or #SOURCE
    -- buscar el rasgo como heading del nivel pedido dentro del capitulo (exacto o normalizado; se
    -- prueba tambien el titulo sin el "(...)" final, para variantes tipo "Truco Adicional (X)").
    local wantTitle = NormalizeHeading(title)
    local wantBase = NormalizeHeading((title:gsub("%s*%b()%s*$", "")))
    at = start
    while true do
        local from, to, hashes, heading = SOURCE:find("\n(#+)%s*([^\n]+)", at)
        if not from or from >= chapterEnd then break end
        if #hashes == (tonumber(level) or 3) then
            -- Algunos headings del manual llevan prefijos HTML de maquetacion (p.ej.
            -- "<span style='margin-left:70px'></span> Estilo de Combate"); se quitan antes de comparar.
            local clean = heading:gsub("<[^>]*>", ""):gsub("^%s+", ""):gsub("%s+$", "")
            local nh = NormalizeHeading(clean)
            if clean == title or nh == wantTitle or (wantBase ~= "" and nh == wantBase) then
                local bodyStart = SOURCE:find("\n", to + 1) or (#SOURCE + 1)
                local nextHeading = FindNextHeading(bodyStart + 1, #hashes)
                local bodyEnd = math.min(nextHeading and (nextHeading - 1) or #SOURCE, chapterEnd)
                local text = CleanMarkdown(SOURCE:sub(bodyStart, bodyEnd), rich)
                return text ~= "" and text or nil
            end
        end
        at = to + 1
    end
    return nil
end

API.FEATURE_TITLES = {
    dh_defensa_sin_armadura = "Defensa sin Armadura",
    dh_iniciacion_illidari = "Iniciación Illidari",
    dh_vision_espectral = "Visión Espectral",
    dh_vil = "Vil",
    dh_mordida_demonio = "Mordida de Demonio",
    dh_momentum = "Moméntum",
    dh_metamorfosis = "Metamorfosis",

    -- Rasgos RENOMBRADOS al nombre canonico de la web/TRP3, que NO es el del manual. El texto
    -- largo se busca por el titulo del manual, asi que sin este mapeo la ficha se quedaria
    -- con la descripcion corta. Al renombrar un rasgo, comprobar siempre si necesita entrada aqui.
    cdm_san_comando_oscuro = "Comando Oscuro",              -- ficha: "Orden oscura"
    monje_tej_niebla_calmante = "Niebla Calmante",      -- ficha: "Niebla reconfortante"
    pic_ase_intuicion = "Intuición del Asesino",        -- ficha: "Intuición de asesino"
    pic_ase_competencia = "Competencia Adicional",      -- ficha: "Competencia con venenos"
    sac_sag_competencia = "Competencia Adicional",      -- ficha: "Saber divino"
    bru_forjado_almas = "Forjado de Almas",             -- ficha: "Forja de almas"
}

-- Devuelve primero el pasaje exacto del Libro y conserva el texto interno como respaldo.
function API.GetFeatureDescription(feature, classId, source, backgroundId, rich)
    if type(feature) ~= "table" then return "" end
    local fallback = tostring(feature.description or "")
    local title = API.FEATURE_TITLES[tostring(feature.id or "")] or tostring(feature.name or "")
    if (source == "class" or source == "Clase" or source == "Subclase")
        and HarfordDnDBook and HarfordDnDBook.GetClassName then
        local className = HarfordDnDBook.GetClassName(classId)
        if className and className ~= "" then
            -- Los rasgos viven bajo "## Rasgos de Clase" dentro del capitulo: busqueda por capitulo.
            return API.GetClassChapterFeature(className, title, 3, rich)
                or API.GetClassChapterFeature(className, title, 4, rich)
                or fallback
        end
    end
    if (source == "bg" or source == "Trasfondo") and backgroundId
        and HarfordDnDBackgrounds and HarfordDnDBackgrounds.GetBackground then
        local background = HarfordDnDBackgrounds.GetBackground(backgroundId)
        if background and title:find("Caracteristica:", 1, true) then
            title = title:gsub("^Caracteristica:", "Característica:")
            return API.GetNestedSection(background.name, 3, title, 4)
                or API.GetNestedSectionMatching(background.name, 3, title, 4)
                or fallback
        end
    end
    return fallback
end

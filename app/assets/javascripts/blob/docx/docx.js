export default class Docx {
  constructor(doc) {
    this.container = document.createElement('div');
    this.container.classList += 'word-doc'
    this.doc = doc;
    this.inList = false;
    this.currentListLevel = 0;
    this.$currentLists = [];
    this.commonColors = {'black': '#000','blue': '#0000FF','cyan':'#00ffff','green':'#008000','magenta':'#ff00ff','red':'#FF0000','yellow':'#ffff00','white':'#FFF','darkBlue':'#00008b','darkCyan':'#008b8b','darkGreen':'#006400','darkMagenta':'#8b008b','darkRed':'#8b0000','darkYellow':'#E5E500','darkGray':'#a9a9a9','lightGray':'#d3d3d3'};
    this.styles = {};
  }

  setStyles(styles) {
    console.log('set styles')
    const $xml = $($.parseXML(styles));
    const $styles = $xml.find('style');
    const attrs = ['b', 'color', 'sz', 'i', 'u'];
    $styles.each((i, style) => {
      const $style = $(style);
      const currentStyle = {};
      attrs.forEach(s => {
        const $styleProp = $style.find(s);
        if($styleProp.length) {
          currentStyle[s] = $styleProp.attr('w:val');
        }
      });
      this.styles[$style.find('name').attr('w:val')] = currentStyle;
    });
  }

  setHexOrCommonColor(colorString) {
    if(this.commonColors.hasOwnProperty(colorString)){
      return this.commonColors[colorString];
    } else {
      return `#${colorString}`;
    }
  }

  parseDoc() {
    const $xml = $($.parseXML(this.doc));
    const $paragraphNodes = $xml.find('p');
    $paragraphNodes.each((i, el) => {
      const $paragraph = $(el);
      const $textNodes = $paragraph.find('t');
      if(!$textNodes.length){
        return;
      }
      var $p = $('<p></p>');
      $textNodes.each((i, el) => {
        const $el = $(el);
        var $span;
        $p = this.setParagraphStyles($paragraph, $p);
        $span = this.setInternalStyles($el, $p);
        $span.text($el.text());
        $p.append($span);
        $(this.container).append($p);
      });
      return;
    });
    return this.container;
  }

  setParagraphStyles($paragraph, $p) {
    $p = this.getJustification($paragraph, $p);
    $p = this.getSavedStyle($paragraph, $p);
    return $p;
  }

  setInternalStyles($el, $p) {
    // const $listRendered = this.getList($r, $p, $paragraph);
    // if($listRendered){
    //   $p = $listRendered;
    // } else {
    //   if(this.inList){
    //     return;
    //   }
    // }
    const $r = $el.parent();
    var $span = $('<span></span>');
    $span = this.getSize($span, $r, $p);
    $span = this.getBold($span, $r, $p);
    $span = this.getItalics($span, $r, $p);
    $span = this.getUnderline($span, $r, $p);
    $span = this.getColor($span, $r, $p);
    $span = this.getHighlight($span, $r, $p);
    return $span;
  }

  getItalics($span, $r, $p) {
    const $italics = $r.find('i');
    if(!$p.attr('data-i') && $italics.length && $italics.attr('w:val') === '1') {
      return this.applyItalics($span);
    }
    return $span;
  }

  applyItalics($el) {
    $el.css('font-style', 'italic');
    $el.attr('data-i', 1);
    return $el;
  }

  getUnderline($span, $r, $p) {
    const $underline = $r.find('u');
    if(!$p.attr('data-u') && $underline.length && $underline.attr('w:val') === 'single') {
      return this.applyUnderLine($span);
    }
    return $span;
  }

  applyUnderLine($el) {
    $el.css('text-decoration', 'underline');
    $el.attr('data-u', 1);
    return $el
  }

  getBold($span, $r, $p) {
    const $bold = $r.find('b');
    if(!$p.attr('data-bold') && $bold.length && $bold.attr('w:val') === '1') {
      return this.applyBold($span);
    }
    return $span;
  }

  applyBold($el) {
    $el.css('font-weight', 'bold');
    $el.attr('data-bold', 1);
    return $el;
  }

  getColor($span, $r, $p) {
    const $color = $r.find('color');
    if(!$p.attr('data-color') && $color.length) {
      return this.applyColor($span, this.setHexOrCommonColor($color.attr('w:val')));
    }
    return $span;
  }

  applyColor($el, val) {
    $el.css('color', val);
    $el.attr('data-color', 1);
    return $el;
  }

  getHighlight($span, $r) {
    const $highlight = $r.find('highlight');
    if($highlight.length) {
      $span.css('background', this.setHexOrCommonColor($highlight.attr('w:val')));
    }
    return $span;
  }

  getSize($span, $r, $p) {
    const size = parseInt($r.find('sz').attr('w:val'))/2 || 11;
    if($p.attr('data-sz')){
      return $span;
    }
    return this.applySize($span, size);
  }

  applySize($el, size) {
    $el.css('font-size',size + 'px');
    $el.attr('data-sz', 1);
    return $el;
  }

  getSavedStyle($paragraph, $p) {
    const $savedStyle = $paragraph.find('pStyle');
    var s = '';
    if($savedStyle.length) {
      const style = $savedStyle.attr('w:val');
      if(this.styles.hasOwnProperty(style)) {
        for(s in this.styles[style]){
          ['b', 'color', 'sz', 'i', 'u']
          switch(s) {
            case 'sz':
            $p = this.applySize($p, this.styles[style][s]);
            break;
            case 'b':
            $p = this.applyBold($p, this.styles[style][s]);
            break;
            case 'color':
            $p = this.applyColor($p, this.styles[style][s]);
            break;
            case 'i':
            $p = this.applyItalics($p, this.styles[style][s]);
            break;
            case 'u':
            $p = this.applyUnderLine($p, this.styles[style][s]);
            break;
          }  
        }
      }
    }
    return $p;
  }

  getJustification($paragraph, $p) {
    const $justificiation = $paragraph.find('jc');
    if($justificiation.length) {
      $p.css('text-align', $justificiation.attr('w:val'));
      return $p;
    }
    return $p;
  }

  getCurrentList() {
    return this.$currentLists[this.$currentLists.length-1];
  }

  getPrevList() {
    return this.$currentLists[this.$currentLists.length-2];
  }

  getListByType(listType) {
    if(listType === 1) {
      return $('<ul></ul>');
    } else {
      return $('<ol></ol>');
    }
  }

  getList($r, $p, $paragraph) {
    const $listInfo = $paragraph.find('numPr');
    var $listItem;
    // has a list and is in a list for the first time;
    if($listInfo.length) {
      var listType = parseInt($listInfo.find('numId').attr('w:val'));
      // not in a list yet but will be
      if(!this.inList) {
        this.currentListLevel = 0;
        this.inList = true;
        this.$currentLists.push(this.getListByType(listType));
        $listItem = $('<li></li>').append($p);
        return this.getCurrentList().append($listItem);
      // was already in a list and will continue to be in a list 
      } else {
        const newListLevel = parseInt($listInfo.find('ilvl').attr('w:val'));
        console.log(newListLevel, this.currentListLevel)
        if(newListLevel > this.currentListLevel) {
          // if we just made a sublist
          this.$currentLists.push(this.getListByType(listType));
          $listItem = this.getPrevList().find('li:last').append(this.getCurrentList());
          this.getPrevList().append($listItem);
          $listItem = $('<li></li>').append($p);
          this.getCurrentList().append($listItem);
          this.currentListLevel = newListLevel
          return null;
        } else if(newListLevel === this.currentListLevel) {

        } else if(newListLevel < this.currentListLevel) {
          // if we just exited a sublist
          this.currentListLevel = newListLevel
          console.log('less than', newListLevel, this.currentListLevel);
          this.$currentLists.pop();
        }

        $listItem = $('<li></li>').append($p);
        return this.getCurrentList().append($listItem);
      }
    } else {
      this.inList = false;
    }
  }
}
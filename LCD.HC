// Device contexts
CDC *fb=DCNew(160,144);
CDC *lcd=DCNew(160,144);
CDC *bgr=DCNew(160,144);
CDC *bg_s=DCNew(256,1);
CDC *sp0_s=DCNew(256,1);
CDC *sp_s;
CDC *win=DCNew(256,256);
CDC *sp0=DCNew(160,144);
CDC *sp1=DCNew(160,144);
CDC *odc;

// Pal to 16 color translations
I64 sp03,sp02,sp01;

DCFill(sp0,15);
DCFill(sp1,TRANSPARENT);

Bool sp0_e=FALSE;
Bool n_scan=FALSE;

// counters, tile-plane, bg, oam sprites
I64 tp_ctr;
I64 bg_tpos;
I64 bg_tctr;
I64 bg_bx;
I64 bg_by;
I64 bg_px;
I64 bg_py;
I64 bg_l=0;
I64 oam_ctr;
I64 sp_px;
I64 sp_py;
I64 sp_cx;
I64 sp_cy;
I64 sp_yf;

// signed tile index & tile-planes
U8 s_tile;
U8 tp0;
U8 tp1;
U8 tp2;
U8 tp3;

U0 FreeLCD()
{
  DCDel(fb);
  DCDel(lcd);
  DCDel(bgr);
  DCDel(bg_s);
  DCDel(sp0_s);
  DCDel(sp_s);
  DCDel(win);
  DCDel(sp0);
  DCDel(sp1);
}

U0 DrawIt(CTask *,CDC *dc)
{
  GrBlot(dc,0,0,lcd);
}

U0 renderBG_ScanLine()
{

  // BG Palette $$FF47 
  SetPal(memory[0xFF47],&bgp0,&bgp1,&bgp2,&bgp3);

  // Draw BG  
  if (memory[0xFF40]>>0&1)
  {
    bg_tpos=0x9800-0x8000;
    if ((memory[0xFF40]>>3&1))
    {
      bg_tpos=0x9C00-0x8000;
    };

    I64 bg_tc_row=0;
    I64 bg_tc_ec=0;
    I64 bg_tc_tc=0;
    while (bg_tc_tc<actualScanLine)
    {
      bg_tc_tc++;
      bg_tc_ec++;
      if (bg_tc_ec>7) { bg_tc_ec=0; bg_tc_row++; };
    };

    bg_tctr=(32*bg_tc_row);
    bg_bx=0;
    bg_by=0;
    bg_px=0;
    bg_py=0;
    while (bg_tctr<((32*bg_tc_row)+32))
    {

      sp0_e=FALSE;
      oam_ctr=156;
      while(oam_ctr>-4)
      {
        if (bg_by>=memory[0xFE00+oam_ctr]-16)
        {
          if (bg_by+16<=memory[0xFE00+oam_ctr]+16)
          {
            sp0_e=TRUE;
            break;
          };
      
        };
        oam_ctr-=4;
      };

      tp_ctr=(2*bg_tc_ec);
      bg_py=0;
        bg_px=0;
        if (!(memory[0xFF40]>>4&1))
        {
          // $$8800 tileset uses signed tile data.
          s_tile=-255+(127+memory[0x8000+bg_tpos+bg_tctr]);
          if (s_tile<128) { s_tile+=256; };
          tp0=memory[0x8000+(tp_ctr+(s_tile*16))+2048];
          tp1=memory[0x8000+(tp_ctr+1+(s_tile*16))+2048];
        }
        else
        {
          // $$8000 uses normal (unsigned)
          tp0=memory[0x8000+(tp_ctr+(memory[0x8000+bg_tpos+bg_tctr]*16))];
          tp1=memory[0x8000+(tp_ctr+1+(memory[0x8000+bg_tpos+bg_tctr]*16))];
        };
        while(bg_px<8)
        {
          if ((tp1>>bg_px)&1) {
            if((tp0>>bg_px)&1){bg_s->color=bgp3;}else{bg_s->color=bgp2;};
          } else {
            if((tp0>>bg_px)&1){bg_s->color=bgp1;}else
            {
              
             if(sp0_e)
             { bg_s->color=TRANSPARENT;
             } else { bg_s->color=bgp0; };
          
            };
          };
          if (sp0_e)
          {   
            sp0_s->color=bgp0;
            GrPlot(sp0_s,bg_bx+(7-bg_px),0);
          };
            GrPlot(bg_s,bg_bx+(7-bg_px),0);
          bg_px++;
        };
      bg_bx+=8;
      if (bg_bx>255) { bg_bx=0;bg_by+=8; };
      bg_tctr++;  
    };
  };

    GrBlot(bgr,-memory[0xFF43],-memory[0xFF42]+actualScanLine,bg_s);
    if (memory[0xFF42])
    {
      GrBlot(bgr,memory[0xFF43],memory[0xFF42]+256+actualScanLine,bg_s);
    };
    if (memory[0xFF43])
    {
      GrBlot(bgr,-memory[0xFF43]+256,-memory[0xFF42]+actualScanLine,bg_s);
    };
    if (memory[0xFF42] && memory[0xFF43])
    {
      GrBlot(bgr,-memory[0xFF43]+256,-memory[0xFF42]+256+actualScanLine,bg_s);
    };

    if (sp0_e)
    {
     GrBlot(sp0,-memory[0xFF43],-memory[0xFF42]+actualScanLine,sp0_s);
     if (memory[0xFF42])
     {
       GrBlot(sp0,memory[0xFF43],memory[0xFF42]+256+actualScanLine,sp0_s);
     };
     if (memory[0xFF43])
     {
       GrBlot(sp0,-memory[0xFF43]+256,-memory[0xFF42]+actualScanLine,sp0_s);
     };
     if (memory[0xFF42] && memory[0xFF43])
     { 
       GrBlot(sp0,-memory[0xFF43]+256,-memory[0xFF42]+256+actualScanLine,sp0_s);
     };
    };

}

U0 drawFrameBuffer()
{

  // if sprites enabled, draw SP0 to framebuffer
  if (memory[0xFF40]>>1&1){ GrBlot(fb,0,0,sp0); };
  // if bg enabled, draw BG rasterized to framebuffer
  if (memory[0xFF40]>>0&1){ GrBlot(fb,0,0,bgr); };  
  // if sprites enabled, draw SP1 to framebuffer
  if (memory[0xFF40]>>1&1){ GrBlot(fb,0,0,sp1); };

  // if LCD enabled, draw framebuffer to LCD
  if ((memory[0xFF40]>>7)&1){
      GrBlot(lcd,0,0,fb);  
  } else {
    DCFill(lcd,15);
  };
  DCFill(bgr,TRANSPARENT);
};

U0 renderSprites()
{
  DCFill(sp1,TRANSPARENT);

  // OBP0 Palette $$FF48 
  SetPal(memory[0xFF48],&obp00,&obp01,&obp02,&obp03);
  // OBP1 Palette $$FF49 
  SetPal(memory[0xFF49],&obp10,&obp11,&obp12,&obp13);

  s_tile=0;

  // Draw Sprites from OAM
  if (memory[0xFF40]>>1&1)
  {
    oam_ctr=156;
    while(oam_ctr>-4)
    {
      // sprite palettes
      if ((memory[0xFE00+oam_ctr+3]>>4)&1)
      { sp03=obp13; sp02=obp12; sp01=obp11; }
      else
      { sp03=obp03; sp02=obp02; sp01=obp01; };
      
       //y (draw on screen-16)
       //x (draw on screen-8)
       //unsigned tile starting at $$8000
      tp_ctr=0;
      bg_py=0;
      sp_py=0;
      sp_cy=1;
      sp_yf=0;
      if ((memory[0xFE00+oam_ctr+3]>>6)&1) { sp_py=7; sp_cy=-1; sp_yf=1; };
       
      while (tp_ctr<16)      
      {
        bg_px=0;
        sp_px=0;
        sp_cx=1;
        if ((memory[0xFE00+oam_ctr+3]>>5)&1) { sp_px=7; sp_cx=-1; };

          if (memory[0xFF40]>>2&1)
          {
            tp0=memory[0x8000+(tp_ctr+((memory[0xFE00+oam_ctr+2]&0xFE)*16))];
            tp1=memory[0x8000+(tp_ctr+1+((memory[0xFE00+oam_ctr+2]&0xFE)*16))];
            tp2=memory[0x8000+(tp_ctr+((memory[0xFE00+oam_ctr+2]|1)*16))];
            tp3=memory[0x8000+(tp_ctr+1+((memory[0xFE00+oam_ctr+2]|1)*16))];

          } else {
            tp0=memory[0x8000+(tp_ctr+(memory[0xFE00+oam_ctr+2]*16))];
            tp1=memory[0x8000+(tp_ctr+1+(memory[0xFE00+oam_ctr+2]*16))];
            tp2=0;
            tp3=0;
          };

          if ((memory[0xFE00+oam_ctr+3]>>7)&1==0)
          {
            odc=sp1;
          } else {
            odc=sp0;
          };

          while(bg_px<8)       
          {
            if ((tp1>>bg_px)&1) {
              if((tp0>>bg_px)&1){odc->color=sp03;}else{odc->color=sp02;};
            } else {
              if((tp0>>bg_px)&1){odc->color=sp01;}else{odc->color=TRANSPARENT;};
            };
            if (odc->color!=TRANSPARENT)         
            { 
              GrPlot(odc,memory[0xFE00+oam_ctr+1]-8+(7-sp_px),(8*sp_yf)+memory[0xFE00+oam_ctr]-16+sp_py);
            };

            if (tp3)
            {
              if ((tp3>>bg_px)&1) {
                if((tp2>>bg_px)&1){odc->color=sp03;}else{odc->color=sp02;};
              } else {
                if((tp2>>bg_px)&1){odc->color=sp01;}else{odc->color=TRANSPARENT;};             };
              if (odc->color!=TRANSPARENT)         
              { 
                GrPlot(odc,memory[0xFE00+oam_ctr+1]-8+(7-sp_px),(-8*sp_yf)+8+memory[0xFE00+oam_ctr]-16+sp_py);
              }; 

            };
          
            bg_px++;
            sp_px+=sp_cx;
          };
          bg_py++;
          sp_py+=sp_cy;
          tp_ctr+=2;
      };
      bg_bx+=8;
      if (bg_bx>255) { bg_bx=0;bg_by+=8; };
      oam_ctr-=4;
    };
  };
};

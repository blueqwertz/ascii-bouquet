#!/usr/bin/env bash
# Ascii Flower Bouquet - bash/awk port of bouquet3d.py
# Original: https://github.com/alishsharma17/Ascii-Flower-Bouquet-
# MIT License, Copyright (c) 2026 Alish Sharma (see LICENSE)
# Runs on a stock Mac (bash 3.2 + awk), no Python needed.
# Usage:  bash bouquet.sh        or        curl -fsSL <raw-url> | bash
# Stop with Ctrl+C.

# ---- settings (change these) ----------------------------------------
FPS=24
SPIN_SPEED=0.6
TILT=0.30
CAM_DIST=4.0
MESSAGE="for you ♥"
NUM_HEARTS=18
HINT="@alishsharma on tiktok!"
# ---------------------------------------------------------------------

bouquet_main() {
  # tty for size + output also works when script comes via "curl | bash"
  TTY="${BQ_TTY:-/dev/tty}"
  [ -r "$TTY" ] || { echo "Needs an interactive terminal." >&2; return 1; }

  # split strings into chars (UTF-8 aware) joined by \001 for awk
  local oldlc="$LC_ALL" i msg_split="" hint_split="" sep=$'\001'
  export LC_ALL=en_US.UTF-8
  for ((i = 0; i < ${#MESSAGE}; i++)); do msg_split+="${MESSAGE:i:1}$sep"; done
  for ((i = 0; i < ${#HINT}; i++)); do hint_split+="${HINT:i:1}$sep"; done
  if [ -n "$oldlc" ]; then export LC_ALL="$oldlc"; else unset LC_ALL; fi

  cleanup() {
    printf '\033[0m\033[?25h\033[2J\033[H' >>"$TTY"
    printf '\033[38;5;205m♥\033[0m\n' >>"$TTY"
  }
  trap 'cleanup; trap - INT TERM EXIT; exit 0' INT TERM
  trap 'cleanup' EXIT

  printf '\033[?25l\033[2J' >>"$TTY"

  BQ_MSG="$msg_split" BQ_HINT="$hint_split" LC_ALL=C awk \
    -v FPS="$FPS" -v SPIN_SPEED="$SPIN_SPEED" -v TILT="$TILT" \
    -v CAM_DIST="$CAM_DIST" -v NUM_HEARTS="$NUM_HEARTS" -v TTY="$TTY" '
function mkpal(name, s,   a, n, k) {
  n = split(s, a, " ")
  for (k = 1; k <= n; k++) PAL[name, k - 1] = a[k] + 0
  PALN[name] = n
}
function pc(name, b) { return PAL[name, int(b * PALN[name])] }
function clamp(b) { return b > 0.999 ? 0.999 : (b < 0 ? 0 : b) }
function absf(x) { return x < 0 ? -x : x }
function uniform(a, b) { return a + (b - a) * rand() }
function normv(x, y, z,   m) {
  m = sqrt(x * x + y * y + z * z); if (m == 0) m = 1
  NX = x / m; NY = y / m; NZ = z / m
}
function addpt(x, y, z, nx, ny, nz, pal, tone, two, ov) {
  NP++
  PX[NP] = x; PY[NP] = y; PZ[NP] = z
  PNX[NP] = nx; PNY[NP] = ny; PNZ[NP] = nz
  PPAL[NP] = pal; PTONE[NP] = tone; PTWO[NP] = two; POV[NP] = ov
}

function build_scene() {  # locals are globals here (awk arg limit)
  srand(21)
  neck0 = 0; neck1 = -0.12; neck2 = 0
  C1 = 0.12; D = 0.64; N = 10
  golden = PI * (3 - sqrt(5))
  for (i = 0; i < N; i++) {
    el = (88 - 60 * sqrt(i / (N - 1))) * PI / 180
    az = i * golden
    dx = cos(el) * cos(az); dy = sin(el); dz = cos(el) * sin(az)
    sc = D * uniform(0.92, 1.05)
    HX[i] = dx * sc; HY[i] = C1 + dy * sc; HZ[i] = dz * sc
    normv(dx, dy, dz); AX[i] = NX; AY[i] = NY; AZ[i] = NZ
  }

  tul[3] = 1; tul[8] = 1
  disc_i = 0; NF = 0
  for (idx = 0; idx < N; idx++) {
    bx = HX[idx] - AX[idx] * 0.03; by = HY[idx] - AY[idx] * 0.03; bz = HZ[idx] - AZ[idx] * 0.03
    for (j = 0; j < 70; j++) {
      t = j / 69
      addpt(bx + (neck0 - bx) * t, by + (neck1 - by) * t, bz + (neck2 - bz) * t,
            AX[idx], 0, AZ[idx], "GREENS", -0.15, 1, "")
    }
    NF++
    FX[NF] = HX[idx]; FY[NF] = HY[idx]; FZ[NF] = HZ[idx]
    if (idx in tul) {
      n_t = (idx > 3) ? 1 : 0
      FKIND[NF] = "tulip"; FPAL[NF] = TULIP[n_t % 3]; FCPAL[NF] = ""; FNPET[NF] = 0
      FR[NF] = 0.11; FSEED[NF] = uniform(0, 6.28)
    } else {
      pl = disc_i % 6; disc_i++
      FKIND[NF] = "disc"; FPAL[NF] = DPET[pl]; FCPAL[NF] = DCEN[pl]; FNPET[NF] = DNP[pl]
      FR[NF] = uniform(0.12, 0.14); FSEED[NF] = uniform(0, 6.28)
    }
  }

  for (i = 0; i < 8; i++) {
    a = (i + 0.4) / 8 * 2 * PI
    c = cos(a); s = sin(a)
    bx = 0.26 * c; by = 0.30; bz = 0.26 * s
    normv(c, 0.15, s); dx = NX; dy = NY; dz = NZ
    sdx = -s; sdz = c
    # cross(side, d) with side=(sdx,0,sdz)
    normv(0 * dz - sdz * dy, sdz * dx - sdx * dz, sdx * dy - 0 * dx); n0 = NX; n1 = NY; n2 = NZ
    L = 0.30; W = 0.07
    for (ti = 0; ti < 32; ti++) {
      t = ti / 31
      for (wi = -5; wi <= 5; wi++) {
        w = wi / 5
        curl = 0.025 * w * w
        rib = (wi == 0) ? -0.25 : 0
        addpt(bx + dx * L * t + sdx * W * sin(PI * t) * w + n0 * curl,
              by + dy * L * t - 0.10 * t * t + n1 * curl,
              bz + dz * L * t + sdz * W * sin(PI * t) * w + n2 * curl,
              n0, n1, n2, "GREENS", rib, 1, "")
      }
    }
  }

  y0 = -0.20; y1 = 0.30; r0 = 0.06; r1 = 0.36
  k = (r1 - r0) / (y1 - y0)
  rings = 50
  for (i = 0; i < rings; i++) {
    t = i / (rings - 1)
    r = r0 + (r1 - r0) * t
    count = int(170 * r); if (count < 8) count = 8
    for (j = 0; j < count; j++) {
      ph = (j + rand()) / count * 2 * PI
      c = cos(ph); s = sin(ph)
      y = y0 + (y1 - y0) * t
      if (t > 0.9) y += 0.03 * sin(9 * ph)
      fold = 0.3 * (absf(sin(5 * ph)) - 0.6)
      normv(c, -k, s)
      addpt(r * c, y, r * s, NX, NY, NZ, "PAPER", fold, 0, "")
    }
  }

  for (i = 0; i < 7; i++) {
    a = i / 7 * 2 * PI
    sx = 0.025 * cos(a); sz = 0.025 * sin(a)
    for (j = 0; j < 40; j++) {
      t = j / 39
      addpt(sx * (1 + 1.2 * t), -0.20 - 0.30 * t, sz * (1 + 1.2 * t),
            cos(a), 0, sin(a), "GREENS", -0.1, 1, "")
    }
  }

  by = -0.12
  br = r0 + k * (by - y0) + 0.01
  for (j = 0; j < 90; j++) {
    ph = j / 90 * 2 * PI
    for (dxx = -1; dxx <= 1; dxx++)
      addpt(br * cos(ph), by + dxx * 0.012, br * sin(ph), cos(ph), 0, sin(ph), "RIBBON", 0, 0, "")
  }
  kz = br + 0.01
  for (side = -1; side <= 1; side += 2) {
    for (j = 0; j < 70; j++) {
      a = j / 70 * 2 * PI
      lx = side * (0.07 + 0.07 * cos(a))
      ly = 0.04 * sin(a) + 0.02 * (0.07 + 0.07 * cos(a)) / 0.14
      for (fi = 0; fi < 2; fi++) {
        fill = fi ? 0.7 : 1.0
        addpt(lx * fill, by + ly * fill, kz + 0.01, side * 0.3, 0.2, 0.93, "RIBBON", 0.1, 1, "")
      }
    }
    for (j = 0; j < 30; j++) {
      t = j / 29
      addpt(side * 0.06 * t, by - 0.15 * t, kz + 0.015,
            side * 0.2, 0, 0.98, "RIBBON", -0.05 + 0.05 * sin(t * 9), 1, "")
    }
  }
  for (dxx = -1; dxx <= 1; dxx++)
    addpt(dxx * 0.01, by, kz + 0.02, 0, 0, 1, "RIBBON", 0.2, 1, "@")

  NB = 0
  for (i = 0; i < 90; i++) {
    a = rand() * 2 * PI
    el2 = uniform(0.3, 1.4)
    rr = uniform(0.40, 0.58)
    NB++
    BX[NB] = rr * cos(a) * cos(el2); BY[NB] = C1 + rr * sin(el2)
    BZ[NB] = rr * sin(a) * cos(el2); BPH[NB] = uniform(0, 6.28)
  }

  NS = 0
  for (i = 0; i < 30; i++) {
    a = rand() * 2 * PI
    rr = uniform(0.75, 0.95)
    NS++
    SX[NS] = rr * cos(a); SY[NS] = uniform(-0.3, 1.0); SZ[NS] = rr * sin(a)
    SPH[NS] = uniform(0, 6.28); SSP[NS] = uniform(1.5, 4.0)
  }
}

function update_hearts(dt,   h) {
  while (NH < NUM_HEARTS) {
    HTX[NH] = rand(); HTY[NH] = 1 + rand(); HTS[NH] = uniform(0.03, 0.08)
    HTP[NH] = uniform(0, 6.28); HTC[NH] = HEARTC[int(rand() * 6)]
    NH++
  }
  for (h = 0; h < NH; h++) {
    HTY[h] -= HTS[h] * dt
    if (HTY[h] < 0) { HTX[h] = rand(); HTY[h] = 1; HTC[h] = HEARTC[int(rand() * 6)] }
  }
}

# projection: sets PC, PR (ints), PFX, PFY (floats), PZT, PF
function project(x, y, z,   xr, zr, yp, yt) {
  xr = x * CA - z * SA
  zr = x * SA + z * CA
  yp = y - PIVOT_Y
  yt = yp * CT - zr * ST
  PZT = yp * ST + zr * CT
  PF = CAM_DIST / (CAM_DIST - PZT)
  PFX = CX + xr * PF * SXS
  PFY = CY - yt * PF * SCALE
  PC = int(PFX); PR = int(PFY)
}

function plot(col, row, z, ch, color,   id) {
  if (row >= 0 && row < VROWS && col >= 0 && col < COLS) {
    id = row * COLS + col
    if (z > ZB[id]) { ZB[id] = z; CH[id] = ch; CO[id] = color }
  }
}

function render(t,   n, i, ang, h, col, row, nxr, nzr, nyt, nzt, dot, b, ch, pal, fx, fy, zt, f,
                     rx, ry, dim, rot, r0, r1, c0, c1, dy, dx, s, ph, reach, edge, v, hw, xn,
                     seam, star, tw, mrow, start, shift, out, line, r, c, last, cl, m) {
  n = COLS * ROWS
  for (i = 0; i < n; i++) { CH[i] = " "; CO[i] = 0; ZB[i] = -1e9 }

  VROWS = ROWS - 2
  SCALE = (VROWS - 2) / 1.45
  if ((COLS - 2) / 2.7 < SCALE) SCALE = (COLS - 2) / 2.7
  if (SCALE < 1) SCALE = 1
  SXS = SCALE * 2
  CX = COLS / 2
  CY = 1 + 0.78 * SCALE

  ang = t * SPIN_SPEED
  CA = cos(ang); SA = sin(ang)

  for (h = 0; h < NH; h++) {
    m = int((HTX[h] + 0.015 * sin(t * 1.2 + HTP[h])) * COLS) % COLS
    if (m < 0) m += COLS
    plot(m, int(HTY[h] * VROWS), -50, "\342\231\245", HTC[h])
  }

  for (i = 1; i <= NP; i++) {
    project(PX[i], PY[i], PZ[i])
    nxr = PNX[i] * CA - PNZ[i] * SA
    nzr = PNX[i] * SA + PNZ[i] * CA
    nyt = PNY[i] * CT - nzr * ST
    nzt = PNY[i] * ST + nzr * CT
    dot = nxr * LX + nyt * LY + nzt * LZ
    if (PTWO[i] && dot < 0) dot = -dot * 0.55
    b = 0.25 + 0.75 * (dot > 0 ? dot : 0) + PTONE[i]
    b = clamp(b)
    ch = POV[i] != "" ? POV[i] : substr(SHADE, int(b * 8) + 1, 1)
    plot(PC, PR, PZT, ch, pc(PPAL[i], b))
  }

  for (i = 1; i <= NF; i++) {
    project(FX[i], FY[i], FZ[i])
    fx = PFX; fy = PFY; zt = PZT; f = PF
    rx = FR[i] * f * SXS; ry = FR[i] * f * SCALE
    dim = (zt + 0.6) / 1.2; dim = dim > 1 ? 1 : (dim < 0 ? 0 : dim)
    dim = -0.4 * (1 - dim)
    rot = FSEED[i] + ang * 0.7
    pal = FPAL[i]
    r0 = int(fy - ry) - 1; r1 = int(fy + ry) + 1
    c0 = int(fx - rx) - 1; c1 = int(fx + rx) + 1
    for (row = r0; row <= r1; row++) {
      dy = (row + 0.5 - fy) / ry
      for (col = c0; col <= c1; col++) {
        dx = (col + 0.5 - fx) / rx
        if (FKIND[i] == "disc") {
          s = sqrt(dx * dx + dy * dy)
          if (s > 1) continue
          if (s < 0.3) {
            b = clamp(0.55 - 0.35 * dx - 0.35 * dy + dim)
            plot(col, row, zt + 0.06, s < 0.17 ? "@" : "o", pc(FCPAL[i], b))
            continue
          }
          ph = atan2(dy, dx)
          reach = 0.32 + 0.68 * absf(cos(FNPET[i] * (ph + rot) / 2)) ^ 0.7
          if (s > reach) continue
          edge = (s > reach - 0.14) ? -0.22 : 0
          b = clamp(0.62 - 0.22 * dx - 0.28 * dy + 0.12 * s + edge + dim)
          plot(col, row, zt + 0.04 * (1 - s), substr(PSHADE, int(b * 4) + 1, 1), pc(pal, b))
        } else {
          v = (1 - dy) / 2
          if (v < 0 || v > 1) continue
          m = v * 1.5 + 0.05; if (m > 1) m = 1
          hw = 0.62 * sin(PI * 0.5 * m)
          if (hw <= 0 || absf(dx) > hw) continue
          xn = dx / hw
          if (v > 0.72 + 0.28 * cos(1.5 * PI * xn) ^ 2) continue
          seam = (absf(absf(xn) - 0.33) < 0.12 && v > 0.3) ? -0.25 : 0
          b = clamp(0.55 - 0.3 * xn + 0.1 * v + seam + dim)
          plot(col, row, zt + 0.03, substr(PSHADE, int(b * 4) + 1, 1), pc(pal, b))
        }
      }
    }
  }

  for (i = 1; i <= NB; i++) {
    project(BX[i], BY[i], BZ[i])
    star = sin(t * 2 + BPH[i]) > 0.6
    plot(PC, PR, PZT + 0.02, star ? "*" : "\302\267", star ? 231 : 255)
  }

  for (i = 1; i <= NS; i++) {
    project(SX[i], SY[i], SZ[i])
    tw = sin(t * SSP[i] + SPH[i])
    if (tw > 0.85) plot(PC, PR, PZT, "*", 231)
    else if (tw > 0.4) plot(PC, PR, PZT, "+", 225)
    else if (tw > 0) plot(PC, PR, PZT, "\302\267", 218)
  }

  mrow = ROWS - 2
  start = int((COLS - NMSG) / 2); if (start < 0) start = 0
  shift = int(t * 6)
  for (i = 0; i < NMSG; i++)
    if (start + i < COLS) { id = mrow * COLS + start + i; CH[id] = MSG[i + 1]; CO[id] = MSGC[(i + shift) % 10] }
  start = int((COLS - NHINT) / 2); if (start < 0) start = 0
  for (i = 0; i < NHINT; i++)
    if (start + i < COLS) { id = (ROWS - 1) * COLS + start + i; CH[id] = HINTA[i + 1]; CO[id] = 238 }

  out = "\033[H"
  for (r = 0; r < ROWS; r++) {
    line = ""; last = -1; i = r * COLS
    for (c = 0; c < COLS; c++) {
      ch = CH[i + c]
      if (ch != " ") { cl = CO[i + c]; if (cl != last) { last = cl; line = line "\033[38;5;" cl "m" } }
      line = line ch
    }
    out = out line (r < ROWS - 1 ? "\n" : "")
  }
  printf "%s\033[0m", out > TTY
  fflush(TTY)
}

function get_size(   cmd, line, a) {
  cmd = "stty size < " TTY " 2>/dev/null"
  line = ""
  cmd | getline line
  close(cmd)
  if (split(line, a, " ") == 2) { TR = a[1] + 0; TC = a[2] + 0 } else { TR = 30; TC = 80 }
}

function now_sec(   s) { srand(); s = srand(++SEEDCTR + 7919); return s }

BEGIN {
  PI = atan2(0, -1)
  PIVOT_Y = 0.2
  SHADE = ".:-=+*%@"; PSHADE = "+*#%"
  CT = cos(TILT); ST = sin(TILT)
  normv(-0.45, 0.6, 0.66); LX = NX; LY = NY; LZ = NZ

  mkpal("WHITE", "244 248 251 254 255 231")
  mkpal("PINK", "125 162 168 205 211 218 225")
  mkpal("RED", "52 88 124 160 196 203")
  mkpal("PURPLE", "54 91 97 134 140 183")
  mkpal("YELLOW", "136 178 214 220 226 229")
  mkpal("ORANGE", "130 166 202 208 214 216")
  mkpal("GOLD", "94 136 178 214 220")
  mkpal("DARK", "52 58 94 130 136")
  mkpal("GREENS", "22 28 28 34 35 71 77 114")
  mkpal("PAPER", "101 144 187 223 230 231")
  mkpal("RIBBON", "88 125 161 197 204 211")
  split("161 197 204 205 211 218", tmp, " "); for (i = 0; i < 6; i++) HEARTC[i] = tmp[i + 1]
  split("161 168 205 211 218 225 218 211 205 168", tmp, " "); for (i = 0; i < 10; i++) MSGC[i] = tmp[i + 1]

  DPET[0] = "WHITE";  DCEN[0] = "GOLD"; DNP[0] = 13
  DPET[1] = "PINK";   DCEN[1] = "GOLD"; DNP[1] = 8
  DPET[2] = "RED";    DCEN[2] = "DARK"; DNP[2] = 6
  DPET[3] = "PURPLE"; DCEN[3] = "GOLD"; DNP[3] = 7
  DPET[4] = "YELLOW"; DCEN[4] = "DARK"; DNP[4] = 12
  DPET[5] = "ORANGE"; DCEN[5] = "DARK"; DNP[5] = 9
  TULIP[0] = "RED"; TULIP[1] = "PINK"; TULIP[2] = "YELLOW"

  NMSG = split(ENVIRON["BQ_MSG"], MSG, "\001") - 1
  NHINT = split(ENVIRON["BQ_HINT"], HINTA, "\001") - 1

  build_scene()
  srand()

  # timing: awk only knows whole seconds, so measure frames per second
  # and derive dt + sleep from that
  period = 1 / FPS; dt = period; slp = 0
  sec = now_sec(); frames = 0; t = 0; lastC = -1; lastR = -1
  get_size()
  maxf = ENVIRON["BQ_FRAMES"] + 0; total = 0   # BQ_FRAMES: stop after N frames (testing)
  while (maxf == 0 || total++ < maxf) {
    if (frames % 12 == 0) get_size()
    COLS = TC - 1; if (COLS < 20) COLS = 20
    ROWS = TR - 1; if (ROWS < 12) ROWS = 12
    if (COLS != lastC || ROWS != lastR) { printf "\033[2J" > TTY; lastC = COLS; lastR = ROWS }
    update_hearts(dt)
    render(t)
    t += dt
    frames++
    if (slp > 0.001 && system("sleep " sprintf("%.3f", slp)) != 0) exit  # Ctrl+C during sleep
    s = now_sec()
    if (s != sec) {
      fps = frames / (s - sec)
      dt = 1 / fps
      slp += (period - dt) * 0.7
      if (slp < 0) slp = 0
      if (slp > period) slp = period
      sec = s; frames = 0
    }
  }
}
'
}

bouquet_main "$@"

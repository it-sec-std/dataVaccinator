#!/bin/sh
# This script was generated using Makeself 2.3.0

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="631576612"
MD5="478c94811147b67263676ebed70ba5fb"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="vaccinator 0.1.7-"
script="./install.sh"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="vaccinator-0.1.7"
filesizes="12792"
keep="n"
nooverwrite="n"
quiet="n"

print_cmd_arg=""
if type printf > /dev/null; then
    print_cmd="printf"
elif test -x /usr/ucb/echo; then
    print_cmd="/usr/ucb/echo"
else
    print_cmd="echo"
fi

unset CDPATH

MS_Printf()
{
    $print_cmd $print_cmd_arg "$1"
}

MS_PrintLicense()
{
  if test x"$licensetxt" != x; then
    echo "$licensetxt"
    while true
    do
      MS_Printf "Please type y to accept, n otherwise: "
      read yn
      if test x"$yn" = xn; then
        keep=n
	eval $finish; exit 1
        break;
      elif test x"$yn" = xy; then
        break;
      fi
    done
  fi
}

MS_diskspace()
{
	(
	if test -d /usr/xpg4/bin; then
		PATH=/usr/xpg4/bin:$PATH
	fi
	df -kP "$1" | tail -1 | awk '{ if ($4 ~ /%/) {print $3} else {print $4} }'
	)
}

MS_dd()
{
    blocks=`expr $3 / 1024`
    bytes=`expr $3 % 1024`
    dd if="$1" ibs=$2 skip=1 obs=1024 conv=sync 2> /dev/null | \
    { test $blocks -gt 0 && dd ibs=1024 obs=1024 count=$blocks ; \
      test $bytes  -gt 0 && dd ibs=1 obs=1024 count=$bytes ; } 2> /dev/null
}

MS_dd_Progress()
{
    if test x"$noprogress" = xy; then
        MS_dd $@
        return $?
    fi
    file="$1"
    offset=$2
    length=$3
    pos=0
    bsize=4194304
    while test $bsize -gt $length; do
        bsize=`expr $bsize / 4`
    done
    blocks=`expr $length / $bsize`
    bytes=`expr $length % $bsize`
    (
        dd ibs=$offset skip=1 2>/dev/null
        pos=`expr $pos \+ $bsize`
        MS_Printf "     0%% " 1>&2
        if test $blocks -gt 0; then
            while test $pos -le $length; do
                dd bs=$bsize count=1 2>/dev/null
                pcent=`expr $length / 100`
                pcent=`expr $pos / $pcent`
                if test $pcent -lt 100; then
                    MS_Printf "\b\b\b\b\b\b\b" 1>&2
                    if test $pcent -lt 10; then
                        MS_Printf "    $pcent%% " 1>&2
                    else
                        MS_Printf "   $pcent%% " 1>&2
                    fi
                fi
                pos=`expr $pos \+ $bsize`
            done
        fi
        if test $bytes -gt 0; then
            dd bs=$bytes count=1 2>/dev/null
        fi
        MS_Printf "\b\b\b\b\b\b\b" 1>&2
        MS_Printf " 100%%  " 1>&2
    ) < "$file"
}

MS_Help()
{
    cat << EOH >&2
${helpheader}Makeself version 2.3.0
 1) Getting help or info about $0 :
  $0 --help   Print this message
  $0 --info   Print embedded info : title, default target directory, embedded script ...
  $0 --lsm    Print embedded lsm entry (or no LSM)
  $0 --list   Print the list of files in the archive
  $0 --check  Checks integrity of the archive

 2) Running $0 :
  $0 [options] [--] [additional arguments to embedded script]
  with following options (in that order)
  --confirm             Ask before running embedded script
  --quiet		Do not print anything except error messages
  --noexec              Do not run embedded script
  --keep                Do not erase target directory after running
			the embedded script
  --noprogress          Do not show the progress during the decompression
  --nox11               Do not spawn an xterm
  --nochown             Do not give the extracted files to the current user
  --target dir          Extract directly to a target directory
                        directory path can be either absolute or relative
  --tar arg1 [arg2 ...] Access the contents of the archive through the tar command
  --                    Following arguments will be passed to the embedded script
EOH
}

MS_Check()
{
    OLD_PATH="$PATH"
    PATH=${GUESS_MD5_PATH:-"$OLD_PATH:/bin:/usr/bin:/sbin:/usr/local/ssl/bin:/usr/local/bin:/opt/openssl/bin"}
	MD5_ARG=""
    MD5_PATH=`exec <&- 2>&-; which md5sum || command -v md5sum || type md5sum`
    test -x "$MD5_PATH" || MD5_PATH=`exec <&- 2>&-; which md5 || command -v md5 || type md5`
	test -x "$MD5_PATH" || MD5_PATH=`exec <&- 2>&-; which digest || command -v digest || type digest`
    PATH="$OLD_PATH"

    if test x"$quiet" = xn; then
		MS_Printf "Verifying archive integrity..."
    fi
    offset=`head -n 521 "$1" | wc -c | tr -d " "`
    verb=$2
    i=1
    for s in $filesizes
    do
		crc=`echo $CRCsum | cut -d" " -f$i`
		if test -x "$MD5_PATH"; then
			if test x"`basename $MD5_PATH`" = xdigest; then
				MD5_ARG="-a md5"
			fi
			md5=`echo $MD5 | cut -d" " -f$i`
			if test x"$md5" = x00000000000000000000000000000000; then
				test x"$verb" = xy && echo " $1 does not contain an embedded MD5 checksum." >&2
			else
				md5sum=`MS_dd_Progress "$1" $offset $s | eval "$MD5_PATH $MD5_ARG" | cut -b-32`;
				if test x"$md5sum" != x"$md5"; then
					echo "Error in MD5 checksums: $md5sum is different from $md5" >&2
					exit 2
				else
					test x"$verb" = xy && MS_Printf " MD5 checksums are OK." >&2
				fi
				crc="0000000000"; verb=n
			fi
		fi
		if test x"$crc" = x0000000000; then
			test x"$verb" = xy && echo " $1 does not contain a CRC checksum." >&2
		else
			sum1=`MS_dd_Progress "$1" $offset $s | CMD_ENV=xpg4 cksum | awk '{print $1}'`
			if test x"$sum1" = x"$crc"; then
				test x"$verb" = xy && MS_Printf " CRC checksums are OK." >&2
			else
				echo "Error in checksums: $sum1 is different from $crc" >&2
				exit 2;
			fi
		fi
		i=`expr $i + 1`
		offset=`expr $offset + $s`
    done
    if test x"$quiet" = xn; then
		echo " All good."
    fi
}

UnTAR()
{
    if test x"$quiet" = xn; then
		tar $1vf - 2>&1 || { echo Extraction failed. > /dev/tty; kill -15 $$; }
    else

		tar $1f - 2>&1 || { echo Extraction failed. > /dev/tty; kill -15 $$; }
    fi
}

finish=true
xterm_loop=
noprogress=n
nox11=n
copy=none
ownership=y
verbose=n

initargs="$@"

while true
do
    case "$1" in
    -h | --help)
	MS_Help
	exit 0
	;;
    -q | --quiet)
	quiet=y
	noprogress=y
	shift
	;;
    --info)
	echo Identification: "$label"
	echo Target directory: "$targetdir"
	echo Uncompressed size: 80 KB
	echo Compression: gzip
	echo Date of packaging: Tue Dec 24 10:25:16 CET 2019
	echo Built with Makeself version 2.3.0 on 
	echo Build command was: "/usr/bin/makeself \\
    \"vaccinator-0.1.7\" \\
    \"vaccinator-0.1.7-.sh\" \\
    \"vaccinator 0.1.7-\" \\
    \"./install.sh\""
	if test x"$script" != x; then
	    echo Script run after extraction:
	    echo "    " $script $scriptargs
	fi
	if test x"" = xcopy; then
		echo "Archive will copy itself to a temporary location"
	fi
	if test x"n" = xy; then
		echo "Root permissions required for extraction"
	fi
	if test x"n" = xy; then
	    echo "directory $targetdir is permanent"
	else
	    echo "$targetdir will be removed after extraction"
	fi
	exit 0
	;;
    --dumpconf)
	echo LABEL=\"$label\"
	echo SCRIPT=\"$script\"
	echo SCRIPTARGS=\"$scriptargs\"
	echo archdirname=\"vaccinator-0.1.7\"
	echo KEEP=n
	echo NOOVERWRITE=n
	echo COMPRESS=gzip
	echo filesizes=\"$filesizes\"
	echo CRCsum=\"$CRCsum\"
	echo MD5sum=\"$MD5\"
	echo OLDUSIZE=80
	echo OLDSKIP=522
	exit 0
	;;
    --lsm)
cat << EOLSM
No LSM.
EOLSM
	exit 0
	;;
    --list)
	echo Target directory: $targetdir
	offset=`head -n 521 "$0" | wc -c | tr -d " "`
	for s in $filesizes
	do
	    MS_dd "$0" $offset $s | eval "gzip -cd" | UnTAR t
	    offset=`expr $offset + $s`
	done
	exit 0
	;;
	--tar)
	offset=`head -n 521 "$0" | wc -c | tr -d " "`
	arg1="$2"
    if ! shift 2; then MS_Help; exit 1; fi
	for s in $filesizes
	do
	    MS_dd "$0" $offset $s | eval "gzip -cd" | tar "$arg1" - "$@"
	    offset=`expr $offset + $s`
	done
	exit 0
	;;
    --check)
	MS_Check "$0" y
	exit 0
	;;
    --confirm)
	verbose=y
	shift
	;;
	--noexec)
	script=""
	shift
	;;
    --keep)
	keep=y
	shift
	;;
    --target)
	keep=y
	targetdir=${2:-.}
    if ! shift 2; then MS_Help; exit 1; fi
	;;
    --noprogress)
	noprogress=y
	shift
	;;
    --nox11)
	nox11=y
	shift
	;;
    --nochown)
	ownership=n
	shift
	;;
    --xwin)
	if test "n" = n; then
		finish="echo Press Return to close this window...; read junk"
	fi
	xterm_loop=1
	shift
	;;
    --phase2)
	copy=phase2
	shift
	;;
    --)
	shift
	break ;;
    -*)
	echo Unrecognized flag : "$1" >&2
	MS_Help
	exit 1
	;;
    *)
	break ;;
    esac
done

if test x"$quiet" = xy -a x"$verbose" = xy; then
	echo Cannot be verbose and quiet at the same time. >&2
	exit 1
fi

if test x"n" = xy -a `id -u` -ne 0; then
	echo "Administrative privileges required for this archive (use su or sudo)" >&2
	exit 1	
fi

if test x"$copy" \!= xphase2; then
    MS_PrintLicense
fi

case "$copy" in
copy)
    tmpdir=$TMPROOT/makeself.$RANDOM.`date +"%y%m%d%H%M%S"`.$$
    mkdir "$tmpdir" || {
	echo "Could not create temporary directory $tmpdir" >&2
	exit 1
    }
    SCRIPT_COPY="$tmpdir/makeself"
    echo "Copying to a temporary location..." >&2
    cp "$0" "$SCRIPT_COPY"
    chmod +x "$SCRIPT_COPY"
    cd "$TMPROOT"
    exec "$SCRIPT_COPY" --phase2 -- $initargs
    ;;
phase2)
    finish="$finish ; rm -rf `dirname $0`"
    ;;
esac

if test x"$nox11" = xn; then
    if tty -s; then                 # Do we have a terminal?
	:
    else
        if test x"$DISPLAY" != x -a x"$xterm_loop" = x; then  # No, but do we have X?
            if xset q > /dev/null 2>&1; then # Check for valid DISPLAY variable
                GUESS_XTERMS="xterm gnome-terminal rxvt dtterm eterm Eterm xfce4-terminal lxterminal kvt konsole aterm terminology"
                for a in $GUESS_XTERMS; do
                    if type $a >/dev/null 2>&1; then
                        XTERM=$a
                        break
                    fi
                done
                chmod a+x $0 || echo Please add execution rights on $0
                if test `echo "$0" | cut -c1` = "/"; then # Spawn a terminal!
                    exec $XTERM -title "$label" -e "$0" --xwin "$initargs"
                else
                    exec $XTERM -title "$label" -e "./$0" --xwin "$initargs"
                fi
            fi
        fi
    fi
fi

if test x"$targetdir" = x.; then
    tmpdir="."
else
    if test x"$keep" = xy; then
	if test x"$nooverwrite" = xy && test -d "$targetdir"; then
            echo "Target directory $targetdir already exists, aborting." >&2
            exit 1
	fi
	if test x"$quiet" = xn; then
	    echo "Creating directory $targetdir" >&2
	fi
	tmpdir="$targetdir"
	dashp="-p"
    else
	tmpdir="$TMPROOT/selfgz$$$RANDOM"
	dashp=""
    fi
    mkdir $dashp $tmpdir || {
	echo 'Cannot create target directory' $tmpdir >&2
	echo 'You should try option --target dir' >&2
	eval $finish
	exit 1
    }
fi

location="`pwd`"
if test x"$SETUP_NOCHECK" != x1; then
    MS_Check "$0"
fi
offset=`head -n 521 "$0" | wc -c | tr -d " "`

if test x"$verbose" = xy; then
	MS_Printf "About to extract 80 KB in $tmpdir ... Proceed ? [Y/n] "
	read yn
	if test x"$yn" = xn; then
		eval $finish; exit 1
	fi
fi

if test x"$quiet" = xn; then
	MS_Printf "Uncompressing $label"
fi
res=3
if test x"$keep" = xn; then
    trap 'echo Signal caught, cleaning up >&2; cd $TMPROOT; /bin/rm -rf $tmpdir; eval $finish; exit 15' 1 2 3 15
fi

leftspace=`MS_diskspace $tmpdir`
if test -n "$leftspace"; then
    if test "$leftspace" -lt 80; then
        echo
        echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (80 KB)" >&2
        if test x"$keep" = xn; then
            echo "Consider setting TMPDIR to a directory with more free space."
        fi
        eval $finish; exit 1
    fi
fi

for s in $filesizes
do
    if MS_dd_Progress "$0" $offset $s | eval "gzip -cd" | ( cd "$tmpdir"; umask $ORIG_UMASK ; UnTAR xp ) 1>/dev/null; then
		if test x"$ownership" = xy; then
			(PATH=/usr/xpg4/bin:$PATH; cd "$tmpdir"; chown -R `id -u` .;  chgrp -R `id -g` .)
		fi
    else
		echo >&2
		echo "Unable to decompress $0" >&2
		eval $finish; exit 1
    fi
    offset=`expr $offset + $s`
done
if test x"$quiet" = xn; then
	echo
fi

cd "$tmpdir"
res=0
if test x"$script" != x; then
    if test x"$verbose" = x"y"; then
		MS_Printf "OK to execute: $script $scriptargs $* ? [Y/n] "
		read yn
		if test x"$yn" = x -o x"$yn" = xy -o x"$yn" = xY; then
			eval "\"$script\" $scriptargs \"\$@\""; res=$?;
		fi
    else
		eval "\"$script\" $scriptargs \"\$@\""; res=$?
    fi
    if test "$res" -ne 0; then
		test x"$verbose" = xy && echo "The program '$script' returned an error code ($res)" >&2
    fi
fi
if test x"$keep" = xn; then
    cd $TMPROOT
    /bin/rm -rf $tmpdir
fi
eval $finish; exit $res
� |�^�<k{�F���_1Ƥ@��vl'�Kr��_�I�i"���H�����=��]��N����443�6�>C+�G����g��}���n�=z=�{z����������ݽݣ��G���x�"0|�]y�gw����W�j� ǩ��w��õ��wt������g���?���_�[Ց�VG��j��6�2L�v���R#�=�	ӷ�L����_��l��l�}<f���cܜz,w�pCp�.>��p����Tr8��؞6�5�S?�k1V�����7���p���vNk�k��t��['5�i�kI�;a��2.*��&x�v��M�7ZGWۓ��X,���� �w�ݪ}B�����[;���?�����b�z��[�\�'�@�xC��X �g����<���Ҙ9� $=?z��6c$�%� ��DŮ����D�V���M)@�۸ǡ[�
�~��S�*\�O�>��E�����:�������t�s�n��s�3`������x?�eS~økzz֢�\��=�g���
���v��M��p�l��CVa��8W�`ab�TbQ��z����>־�-�C�ϭb�m�� �?���o�^�8�)'��Sf�_I�Z��&�72L�a��@��A��e��NH����E��ư�@�-�m����y��ou�/ ����0{�f��B`B�3�a��\����u��!V�Ӫw��k|/�L�I��^�4��vL�<�%�0�Z�b�c�_a�׆�S�/�zo��6~ӛ���B}�E�¢ko�g~0V����p6�E(��Z���v(��M �Uo#߇�)>���p��plk�z���6A~����97����[�P�����F!Dw�O0�����
<�P�=�0�_�n�c�
���Ah@Q_Vzm,�X�p-o��p6�~6�ŵ�X�n�\�����'���jȵt&�E���~������Lk����i"2T������ ?��s��>��(L$O��#bG�����˯�����9�J
2?<��?�쏥W�//��e���6�(�,����ۛn���N���v�=�_��F��M��Ȼz��I��H�s�ͤ�jj�Y�iZ2�6�ӧ��2�H��j/YA�I���4_�|�|���KF\�|�ޝ�W�OL#ǔ_*�]&�!�L|)$�/l�"� s�� �`0lAt�@�_a��$y�h����bT� w�mq��xD�+�%�����G$����#b�xPJ���}�;Ot,?�����.8'�i��9�4��c3�'y>\z9,��}c>�N6&͞�\�E!�H�a-�g�("%<S��{cY�Df�ät�ґ�(P0������
2}�2�2F����3j�&�rD��I��I?��>	��yS�qB[d�I���6����&��Z���<ޱʵ	���2����:)��̳(c�ܭv�k�YK#!���|:��N�"��"u��� �X('��|@�P�p�@f��*H�P~����6�@�A����{����Ap6F�h����b*t(����wԌ�J����]��K�?bG��k	�E�7���bd>vPb.j�@���9�����%��RP�t�7�����!����!���oUlB��TO��V0�.�g	p������W{Uy"����0����0�SyR�hnC������R�>Vr/$�;��(�T�T0���FD.2�5(�g��ǰ��4ȉH?���h)��@.b	⊌�����y#,I���1*c
@T�F��;�a�h9�I�������;�\���.S{TM+����v&\�U�ż]�+�����.���SJX��B(]h(����?B�K��r�l�/�n)��A��J�8ٕX�W4G�c�+�r�1Ĥ�ӈ����I�|�#/r��$Ъ��h�O���.$���1D�#Q��2��
*��*	R+�0X�rI�(!"���9����<a�)7?�Q*q�%�f0��g��Eǭ�W�L�;�T�@������$�-
��\�D��
�:#QG���KM�,����,�W�-��n�0dT��@д���d�%Y�E0DVf
�i���3ʳ����JŰ��,�+p��{�5��0I�X��i��F[h�!$q�D�\�I� �n�����,�W�|-1���N�JF��Z�bl.:.�6�k��It����
S��W[
���@�� ψH��yjخ�GB[������#�LD(+w�1�NIj��$�%K�7� [;m��f_5K�����rwG�Uf��N�����n��lؽ�����i$��*[�2�.r����5�Qÿ���1�X�\~ۑV`y��$�/����%�\BJ��p�!��.{�A���bv��zgr���͒��m�ː�B�o�����~�6o�$����!�`��j8g���_��"ݰ��k뢧�����|�=x8����`/Ug�\
�)ڱ+�}����+kT�_��ZH�tBB��������I�f�-%2����>�6\�{Ai)x�Y1�V���qO��� Z�m&2����
	~a�SL���2R�_D��x�ˍL�Z�wx�|��PyR�$*p�n�
>��w�l�s�W�l.��:#��o�4"%�9G0�k���ȃ싳�>ݝ�9n�߇l�.�_ۂ�i��d�=}H�Q^lv��Ҋ��������+�|�W5�c�G���>�DH��$N��(B*�l�R�$0I����ޫ�j��6����Ĩ�����%�hR"�����"�tD�=r��C�"+�S�[������}d��n���K|�K�(^K�Y~���Ho+l�z�w����L���ozav�Ů��-#���!F䀘r���I���+T�[N޴H�K~��g6ꞅ5�0:�ۨA�!t:��u��A�������/{����as��[s��=p9�M�u$�������	L��?J���OҪ��F���@��C�)������LO1MKٳ�v�V�_�����z\GǇ���I�����G�m�.��Z��/
o��R�;�X@�|c =�ݜ
_.7N�ǹ�y�t���á���.p�4�;����w@qd�|����S>wϨ��9�� Jn����h�X��g��A�����b�߀ ���t�x!q�n���E$�����v����
��z�N�!^�R
E�`>�:<�0���]c��G�L����5����+moȽd�H2��?Aj}�찘��*6�U�]���aA9�`RugC&!#1��4�j�[H�C�9YL���b)���2;9���Kb���@�`0�T4�����W�D.-KMۦM[��xP����B�vS���5�)~1��U+d��&=tK�>�|9�d`+'@-�S�/��%�gJ��.ʕ��Y��3�b�R�fh
��Pr�h���Y�Ì��Ϙu�Ny�k6��_@w��WTm��v�
�s1Nާ�1�sƆ�vG-��>��R�����*`ʗ1W�8i�3�h�&y��s�=)�$��Vp��"6h�1����&UK�<k=#�O�,Q�r��0B|al,	}�bH.��J�ʑ�芤p7Y,���p�ʣA� �̈́u+�S�,ڗ=00�'�'�BQ>��h�]���ã�w���j_��s	�����u!7O�eqO�i=�E�VZ��y)д�S����2��Ԫ�� ���'��4W�y>��6N#0��t�&�4��*��e��sD�M\ǰ��� A�f��xԷ�SR�O��g1�8�(����P����v	m�=oh�E�2�Omڜ�!�,.�v)�M�}�F�NN�TU	A�ȡ�-f{�=j]����nW�p��l�?���@�lR���4_��|��uC��7�P����
���!T�'mI(��p�&a	���u�3���g򞌏>ޤ3�f��Q�4+�k)İ��G�yc�a�~��!cV�ݟ3�T��[}�VJoL�+��u�b�B�[u/���lk|Ř�����0��Ӧ_�ك�W���9$s��d\��7�H�Y���BP��(�Hk&���Nri2�軉8��](�싳�d������t�n7h��+4�3�f�9	X�|J5e4�C
ҿ`�B�+Y��alPxZ����q<h���M[H�x8�%�Fb�)�D��1�'>�_)��I���z*+_M>[Q^~�	��f,O���a���`��U�w�i%��#� FdН�%�rbqx���hq�Y��ϳ�87L�Z+ H��9��]E#��Z!Q�YR�R�k@��(�k!����C������2p/4�^ts�I�1O�&1�
�1����
kl�U�A�cN�>�
3���iᱪ9�r�H�ʛT)���R(����nSrD�{��ON	A�l����.�,���>	D%��x?t�X�[�[zz�H�p ��-z-�q�bHŗj���k�Z�M��b�Ҋ�F�*�:�p;��U�|�o
ǆT�d��W2똨����1Mo�7Yx�d�O�o�v*	˛~�<��c�^:��p�ZZ�5�
�����4Re�-gp���X�=���	x5�g{{�)�+�2D��@�~�zEP#�|\�p��D{�+,���*��-����,�E�L#"?�X|��T�%�O�O֪�B�d��D��  �E�����2���Ă��єq����:���i��qDN@�U�/v�W������H��-�*@��¶��t
6
)�֗=D�c�A��ߝ�s�W*W?6�(�v�q�ԫ�J��o:���=9��V�Tޫ.J��4'���qg�u�W�-��.��J���?���%
\袀E�W�kŷ� 9�������4�o���L�_�x�����7o���l�/���1/*E�ԧ��'�%�ޜZ�v\+�Վ�����j��Y�uJ~�^��]��#NW%��8d��_�P�^x�������Z��t��^�P����(.�u*뮭�-����4=V�k|��n��4�;h7�\�N���@�@оF���w�9�ʩ�L�T�Aw}�RTV5�IK?T��5l{cu�� Y\������ܧhM�&!�Ay*�qƜ��\[�&a�vA��Z^[��/��y�K��$����k6+��f��t�g9����FC�N�[�I��4K�k=��N�q��X�X�Wl}�eq���v�i�@"���F������k�_�ߘ��g����>�0^�_��&�����l�������(�R�������g�/,,}1���a��6��돭�*��<��rRŢ�.��̆� �/���K���%=N�&��S-7�kGG����A鰴_=��l飂R|��3{_u�֒���`�͎�g �0
*{��MV��4#���PS�h<@[`��;C=���~|	t�&7����[���5�&��N��Զ�&���P�t6��@�/��T#77���S}���'ߙ��6F�ٽ�+J�b���ژ�)�0�D�d O�A�[�1W�955�+��wJ��Ɗz��3�`L���Ҏ�h��L��@	ŧ�!/�X.�Un>%c����{��?Ȋ��ξ=�iZ.��E9ё7Ӿ�ۅZ����0|�0���H���$ܷ�N$�:ᨏ��n~l-�%��#�3�.8���%�C{E��a�T���,8��? ^�B�f��E�.r6�Ŋi	Oyo�f�(�;�Y��]�D3nsa;9�]0H�2��?p7+�=�C�����j���k��[��-}�'%.�v�f ?O|�>�ay����1](�Cp�3�M\������\�5��O�A�T��r�9�j�0HL�UH����~�=�vܢ�Y�e=T)�@��.:	��m<�k����\@L��9�eg����(T�<�e��mR�AAQ}vC(\���!�����F �ܟ�ް�Lh5��q#"<�;(��o�̼bi���օi�K��# ��Yf� �3!rl5"��_��:t�����N�QI:L뷣�����Q�i�+�F�0��Ip�)8��C ��8�jq�bt ���b���*eH� �0��n����	L�Ja��:p�`
ԎS��^�M��m��yG}hΠ���#�7C�7(\L���Y�[wT/��yD�b��M�H��2Q~��FL��c�]��xV����G��<{,oʸB��zH'p����cL�Im��G:'㊗@é�]�7���9��w܈+�����˗B@;t� ��q�#�UTzˮ���c�t�m�ȎJ�#;zA1lA,����~��NZLU�r�J����s�J)l�hEUiB+��W��U5<Fr��x���0Ij����u�4�0a?y�#��!��Z�^�t���а�蔺a�97��9�u����m���8Lau���ށ����A��!9�1��㬢��u�aJ��Z���q���Q�J'��-K�|���Xl���m�O��a��'����,�:�n�/^'b�N#1��y�R��ꢣg��un�O ��\��8 G���m�}	~��k�#��D��!��?Ѐ�I4��`U4z�]rT�-�ZGȮ� t����p-� tT�aP"��Uw��&E�c7�5sa�
b�k�*���|%��So@��9�>���`��?����s����iw�]`��2��MKn����ME�됳��s�	V��F .9Ie���i:��b���Pc�(�C�E�g]sC���U���jR0f�=���O{�
���LQL����+akeS0��R�V�9ǹ�5Ln�f��X�w*`����W�߉zNy
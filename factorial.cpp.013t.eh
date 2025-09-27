
;; Function main (main, funcdef_no=1988, decl_uid=49708, cgraph_uid=456, symbol_order=493)

int main ()
{
  struct basic_ostream & D.53836;
  int f;
  int n;
  int i;
  int D.53834;

  std::basic_istream<char>::operator>> (&cin, &n);
  i = 2;
  f = 1;
  goto <D.49738>;
  <D.49739>:
  f = f * i;
  i = i + 1;
  <D.49738>:
  n.0_1 = n;
  if (i <= n.0_1) goto <D.49739>; else goto <D.49737>;
  <D.49737>:
  D.53836 = std::basic_ostream<char>::operator<< (&cout, f);
  _2 = D.53836;
  std::basic_ostream<char>::operator<< (_2, endl);
  D.53834 = 0;
  goto <D.53838>;
  <D.53838>:
  n = {CLOBBER(eol)};
  goto <D.53835>;
  D.53834 = 0;
  goto <D.53835>;
  <D.53835>:
  return D.53834;
  <D.53837>:
  n = {CLOBBER(eol)};
  resx 1
}



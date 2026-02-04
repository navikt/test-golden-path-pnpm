import { Button } from "@navikt/ds-react";
import styles from "./page.module.css";
import { ThumbUpIcon } from "@navikt/aksel-icons";

export default function Home() {
  return (
    <main>
      <Button
        icon={<ThumbUpIcon title="a11y tittel" />}
        className={styles.limeButton}
      >
        knapp
      </Button>
    </main>
  );
}
